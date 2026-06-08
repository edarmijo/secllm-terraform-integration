import os
import yaml
from openai import OpenAI
import time
import traceback
import numpy as np

# torch y anthropic solo se usan en los backends de HuggingFace/llama_cpp y de
# Claude. Para correr con Ollama (API compatible con OpenAI) no hacen falta, asi
# que se importan de forma opcional para no obligar a instalar PyTorch (~2 GB).
try:
    import torch
    HAS_TORCH = True
except ImportError:
    torch = None
    HAS_TORCH = False

try:
    import anthropic
    HAS_ANTHROPIC = True
except ImportError:
    anthropic = None
    HAS_ANTHROPIC = False
from pathlib import Path
import json
import sys
import shutil
import asyncio
from concurrent.futures import ThreadPoolExecutor
import threading
from queue import Queue, Empty
from typing import Optional, Tuple

from cache import *

# Try to import different backends
try:
    from transformers import AutoModelForCausalLM, AutoTokenizer
    HAS_TRANSFORMERS = True
except ImportError:
    HAS_TRANSFORMERS = False

try:
    from llama_cpp import Llama
    HAS_LLAMA_CPP = True
except ImportError:
    HAS_LLAMA_CPP = False

try:
    import mlx.core as mx
    from mlx_lm import load, generate
    HAS_MLX = True
except ImportError:
    HAS_MLX = False


#
# MLX Worker for thread-safe inference
#
class MLXWorker:
    """
    Dedicated worker for MLX inference to avoid threading issues.
    MLX has problems with multi-threading, so we use a single dedicated thread.
    """
    
    def __init__(self):
        self.request_queue = Queue()
        self.result_queues = {}
        self.models = {}
        self.worker_thread = None
        self.running = False
        self._lock = threading.Lock()
        
    def start(self):
        """Start the MLX worker thread"""
        if self.worker_thread is None or not self.worker_thread.is_alive():
            self.running = True
            self.worker_thread = threading.Thread(target=self._worker_loop, daemon=True)
            self.worker_thread.start()
            print("MLX Worker thread started")
    
    def stop(self):
        """Stop the MLX worker thread"""
        self.running = False
        if self.worker_thread and self.worker_thread.is_alive():
            self.request_queue.put(('STOP', None, None))
            self.worker_thread.join(timeout=5)
            print("MLX Worker thread stopped")
    
    def _worker_loop(self):
        """Main worker loop running in dedicated thread"""
        from mlx_lm.sample_utils import make_sampler
        from mlx_lm import stream_generate
        import mlx.core as mx
        
        while self.running:
            try:
                # Get request from queue with timeout
                try:
                    request = self.request_queue.get(timeout=0.1)
                except Empty:
                    continue
                
                command = request[0]
                
                if command == 'STOP':
                    break
                elif command == 'LOAD':
                    request_id, model_path = request[1], request[2]
                    try:
                        print(f"[MLX Worker] Loading model: {model_path}")
                        model, tokenizer = load(model_path)
                        self.models[model_path] = (model, tokenizer)
                        self.result_queues[request_id].put(('SUCCESS', None))
                    except Exception as e:
                        self.result_queues[request_id].put(('ERROR', str(e)))
                    
                elif command == 'INFER':
                    request_id, args = request[1], request[2]
                    model_path = args['model_path']
                    system_prompt = args['system_prompt']
                    user_prompt = args['user_prompt']
                    temperature = args['temperature']
                    max_tokens = args['max_tokens']
                    
                    try:
                        if model_path not in self.models:
                            self.result_queues[request_id].put(('ERROR', f'Model {model_path} not loaded'))
                            continue
                        
                        model, tokenizer = self.models[model_path]
                        
                        # Prepare messages
                        messages = [
                            {"role": "system", "content": system_prompt},
                            {"role": "user", "content": user_prompt}
                        ]
                        
                        prompt = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
                        
                        # Create sampler
                        sampler = make_sampler(
                            temp=temperature if temperature > 0 else 0.1,
                            top_p=1.0,
                            min_p=0.0,
                            min_tokens_to_keep=1
                        )
                        
                        # Generate
                        generated_text = ""
                        log_probs = []
                        input_tokens = 0
                        output_tokens = 0
                        last_response = None
                        
                        for response in stream_generate(
                            model,
                            tokenizer,
                            prompt=prompt,
                            max_tokens=max_tokens,
                            sampler=sampler
                        ):
                            generated_text += response.text
                            
                            # Extract log probability
                            if hasattr(response, 'logprobs') and response.logprobs is not None:
                                logprobs_mx = response.logprobs
                                if isinstance(logprobs_mx, mx.array):
                                    token_logprob = float(logprobs_mx[response.token].item())
                                    log_probs.append(token_logprob)
                            
                            last_response = response
                        
                        # Get token counts
                        if last_response:
                            input_tokens = last_response.prompt_tokens
                            output_tokens = last_response.generation_tokens
                        else:
                            input_tokens = len(tokenizer.encode(prompt))
                            output_tokens = len(tokenizer.encode(generated_text))
                        
                        # Calculate confidence
                        if log_probs:
                            confidence = np.exp(np.mean(log_probs))
                        else:
                            confidence = 0.0
                        
                        result = {
                            'text': generated_text,
                            'confidence': confidence,
                            'input_tokens': input_tokens,
                            'output_tokens': output_tokens,
                            'log_probs': log_probs[:10]  # First 10 for debugging
                        }
                        
                        self.result_queues[request_id].put(('SUCCESS', result))
                        
                    except Exception as e:
                        self.result_queues[request_id].put(('ERROR', str(e)))
                
            except Exception as e:
                print(f"[MLX Worker] Unexpected error: {e}")
                traceback.print_exc()
    
    def load_model(self, model_path: str, timeout: float = 120.0) -> bool:
        """Load a model (thread-safe)"""
        with self._lock:
            request_id = f"load_{time.time()}"
            result_queue = Queue()
            self.result_queues[request_id] = result_queue
            
            self.request_queue.put(('LOAD', request_id, model_path))
            
            try:
                status, result = result_queue.get(timeout=timeout)
                del self.result_queues[request_id]
                
                if status == 'ERROR':
                    raise Exception(f"Failed to load model: {result}")
                return True
            except Empty:
                del self.result_queues[request_id]
                raise TimeoutError(f"Model loading timed out after {timeout}s")
    
    def infer(self, model_path: str, system_prompt: str, user_prompt: str, 
              temperature: float, max_tokens: int, timeout: float = 480.0) -> dict:
        """Run inference (thread-safe)"""
        with self._lock:
            request_id = f"infer_{time.time()}"
            result_queue = Queue()
            self.result_queues[request_id] = result_queue
            
            args = {
                'model_path': model_path,
                'system_prompt': system_prompt,
                'user_prompt': user_prompt,
                'temperature': temperature,
                'max_tokens': max_tokens
            }
            
            self.request_queue.put(('INFER', request_id, args))
            
            try:
                status, result = result_queue.get(timeout=timeout)
                del self.result_queues[request_id]
                
                if status == 'ERROR':
                    raise Exception(f"Inference failed: {result}")
                return result
            except Empty:
                del self.result_queues[request_id]
                raise TimeoutError(f"Inference timed out after {timeout}s")


# Global MLX worker instance
_mlx_worker: Optional[MLXWorker] = None
_mlx_worker_lock = threading.Lock()

def get_mlx_worker() -> MLXWorker:
    """Get or create the global MLX worker"""
    global _mlx_worker
    with _mlx_worker_lock:
        if _mlx_worker is None:
            _mlx_worker = MLXWorker()
            _mlx_worker.start()
    return _mlx_worker


#
# Utility class to store the configuration
#
class Config:
    def __init__(self):
        self._model = "gpt4-o"
        self._url = None
        self._MAX_TOKENS = 8192
        self._temperature = 0
        self._system_prompt = ""
        self._answerKey = ""
        self._row_format = "#{r} {line}"
        self._smells = []
        self._tokens = []
        self._scriptTypePrompt = ""
        self._retries = 1
        self._heuristicScriptIdentification = False
        self._cache = False
        self._use_huggingface = False
        self._hf_model_path = None
        self._device = "auto"
        self._torch_dtype = "auto"
        self._local_files_only = False
        self._backend = "auto"

    @property
    def backend(self):
        return self._backend

    @backend.setter
    def backend(self, value):
        self._backend = value

    @property
    def local_files_only(self):
        return self._local_files_only

    @local_files_only.setter
    def local_files_only(self, value):
        self._local_files_only = value

    @property
    def torch_dtype(self):
        return self._torch_dtype

    @torch_dtype.setter
    def torch_dtype(self, value):
        self._torch_dtype = value

    @property
    def use_huggingface(self):
        return self._use_huggingface

    @use_huggingface.setter
    def use_huggingface(self, value):
        self._use_huggingface = value

    @property
    def hf_model_path(self):
        return self._hf_model_path

    @hf_model_path.setter
    def hf_model_path(self, value):
        self._hf_model_path = value

    @property
    def device(self):
        return self._device

    @device.setter
    def device(self, value):
        self._device = value

    @property
    def cache(self):
        return self._cache

    @cache.setter
    def cache(self, value):
        self._cache = value

    @property
    def url(self):
        return self._url

    @url.setter
    def url(self, value):
        self._url = value

    @property
    def heuristicScriptIdentification(self):
        return self._heuristicScriptIdentification

    @heuristicScriptIdentification.setter
    def heuristicScriptIdentification(self, value):
        self._heuristicScriptIdentification = value

    @property
    def scriptTypePrompt(self):
        return self._scriptTypePrompt

    @scriptTypePrompt.setter
    def scriptTypePrompt(self, value):
        self._scriptTypePrompt = value

    @property
    def model(self):
        return self._model

    @model.setter
    def model(self, value):
        self._model = value

    @property
    def temperature(self):
        return self._temperature

    @temperature.setter
    def temperature(self, value):
        self._temperature = value

    @property
    def MAX_TOKENS(self):
        return self._MAX_TOKENS

    @MAX_TOKENS.setter
    def MAX_TOKENS(self, value):
        self._MAX_TOKENS = value

    @property
    def system_prompt(self):
        return self._system_prompt

    @system_prompt.setter
    def system_prompt(self, value):
        self._system_prompt = value

    @property
    def answerKey(self):
        return self._answerKey

    @answerKey.setter
    def answerKey(self, value):
        self._answerKey = value

    @property
    def row_format(self):
        return self._row_format

    @row_format.setter
    def row_format(self, value):
        self._row_format = value

    @property
    def smells(self):
        return self._smells

    @smells.setter
    def smells(self, value):
        self._smells = value

    @property
    def tokens(self):
        return self._tokens

    @tokens.setter
    def tokens(self, value):
        self._tokens = value

    @property
    def retries(self):
        return self._retries

    @retries.setter
    def retries(self, value):
        self._retries = value


class ModelAnalyzer:
    """Analyze model files to determine format and quantization"""
    
    @staticmethod
    def analyze_model(model_path: str) -> dict:
        """
        Deeply analyze the model to determine its characteristics
        
        Returns:
            dict with keys: format, quantization, backend_preference, reason
        """
        if not os.path.exists(model_path):
            return {
                'format': 'unknown',
                'quantization': None,
                'backend_preference': [],
                'reason': 'Path does not exist'
            }
        
        files = os.listdir(model_path)
        config_path = os.path.join(model_path, 'config.json')
        
        # Check for GGUF files (highest priority for quantized models)
        gguf_files = [f for f in files if f.endswith('.gguf')]
        if gguf_files:
            return {
                'format': 'gguf',
                'quantization': ModelAnalyzer._detect_gguf_quantization(gguf_files[0]),
                'backend_preference': ['llama_cpp'] if HAS_LLAMA_CPP else [],
                'reason': f'Found GGUF file: {gguf_files[0]}'
            }
        
        # Check for MLX format
        if 'weights.npz' in files or any('mlx' in f.lower() for f in files):
            return {
                'format': 'mlx',
                'quantization': 'mlx_quantized' if any('q' in f.lower() for f in files) else None,
                'backend_preference': ['mlx'] if HAS_MLX else [],
                'reason': 'Detected MLX format files'
            }
        
        # Check for safetensors
        safetensor_files = [f for f in files if f.endswith('.safetensors')]
        if safetensor_files:
            config_info = ModelAnalyzer._analyze_config(config_path)
            
            # Determine if it's quantized
            is_quantized = config_info.get('is_quantized', False)
            quant_method = config_info.get('quant_method')
            
            # Check actual file sizes to detect quantization
            if not is_quantized:
                is_quantized, quant_method = ModelAnalyzer._detect_quantization_from_files(
                    model_path, safetensor_files, config_info
                )
            
            backends = []
            
            if is_quantized:
                # For quantized models, prefer specialized backends
                # MLX is best for Apple Silicon
                if HAS_MLX and 'darwin' in sys.platform:
                    backends.append('mlx')
                # Then try llama.cpp for GGUF-compatible quantization
                if HAS_LLAMA_CPP and quant_method and 'gguf' in quant_method.lower():
                    backends.append('llama_cpp')
                # Transformers as fallback only if it supports the quant method
                if quant_method in ['awq', 'gptq'] and HAS_TRANSFORMERS:
                    backends.append('transformers')
            else:
                # For non-quantized, prefer in order of performance
                if HAS_MLX and 'darwin' in sys.platform:
                    backends.append('mlx')
                if HAS_TRANSFORMERS:
                    backends.append('transformers')
            
            return {
                'format': 'safetensors',
                'quantization': quant_method if is_quantized else None,
                'backend_preference': backends,
                'reason': f'Found {len(safetensor_files)} safetensors files' + 
                         (f', quantized with {quant_method}' if is_quantized else ', not quantized'),
                'config_valid': config_info.get('valid', False),
                'has_quant_config': config_info.get('has_quant_config', False)
            }
        
        # Check for PyTorch bins
        pytorch_files = [f for f in files if f.startswith('pytorch_model')]
        if pytorch_files:
            return {
                'format': 'pytorch',
                'quantization': None,
                'backend_preference': ['transformers'] if HAS_TRANSFORMERS else [],
                'reason': f'Found PyTorch model files'
            }
        
        return {
            'format': 'unknown',
            'quantization': None,
            'backend_preference': [],
            'reason': 'Could not determine model format'
        }
    
    @staticmethod
    def _detect_gguf_quantization(filename: str) -> str:
        """Extract quantization level from GGUF filename"""
        parts = filename.lower().split('-')
        for part in parts:
            if 'q' in part and any(c.isdigit() for c in part):
                return part.upper()
        return 'unknown_gguf_quant'
    
    @staticmethod
    def _analyze_config(config_path: str) -> dict:
        """Analyze config.json for quantization info"""
        if not os.path.exists(config_path):
            return {'valid': False, 'has_quant_config': False}
        
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
            
            has_quant_config = 'quantization_config' in config
            quant_config = config.get('quantization_config', {})
            
            is_quantized = False
            quant_method = None
            
            # Check if quantization_config is valid (not empty and has meaningful data)
            if has_quant_config and quant_config and isinstance(quant_config, dict):
                quant_method = quant_config.get('quant_method')
                
                # If no quant_method but has bits/group_size, it's likely a custom quantization
                if not quant_method:
                    if 'bits' in quant_config and 'group_size' in quant_config:
                        bits = quant_config.get('bits')
                        is_quantized = True
                        quant_method = f'custom_{bits}bit'  # e.g., 'custom_4bit'
                    else:
                        # Empty or incomplete quantization config
                        has_quant_config = False
                elif quant_method.strip():
                    # Has a valid quant_method
                    if quant_method in ['awq', 'gptq', 'bitsandbytes']:
                        is_quantized = True
                else:
                    # Empty quant_method
                    has_quant_config = False
            else:
                # quantization_config exists but is empty or invalid
                has_quant_config = False
            
            return {
                'valid': True,
                'has_quant_config': has_quant_config,
                'is_quantized': is_quantized,
                'quant_method': quant_method if is_quantized else None,
                'hidden_size': config.get('hidden_size'),
                'vocab_size': config.get('vocab_size'),
                'needs_removal': 'quantization_config' in config and not is_quantized  # Remove if present but not actually quantized
            }
        except Exception as e:
            return {'valid': False, 'error': str(e)}
    
    @staticmethod
    def _detect_quantization_from_files(model_path: str, safetensor_files: list, 
                                       config_info: dict) -> tuple:
        """Detect if model is quantized by comparing expected vs actual file sizes"""
        try:
            import safetensors.torch as st
            
            first_file = os.path.join(model_path, safetensor_files[0])
            tensors = st.load_file(first_file)
            
            # Check for quantized dtypes in the actual tensors
            for tensor in tensors.values():
                dtype_str = str(tensor.dtype)
                if 'int8' in dtype_str or 'uint8' in dtype_str:
                    return True, 'int8'
                if 'int4' in dtype_str or 'uint4' in dtype_str:
                    return True, 'int4'
            
            hidden_size = config_info.get('hidden_size', 0)
            
            # Heuristic: check total model size
            if hidden_size:
                total_size = sum(os.path.getsize(os.path.join(model_path, f)) 
                               for f in safetensor_files)
                size_gb = total_size / (1024**3)
                
                if '32B' in model_path or '32b' in model_path:
                    # A 32B model should be ~60-65GB in fp16
                    if size_gb < 40:
                        if size_gb < 25:
                            return True, 'int4_or_lower'
                        else:
                            return True, 'int8_or_mixed'
                elif '7B' in model_path or '7b' in model_path:
                    # A 7B model should be ~14GB in fp16
                    if size_gb < 10:
                        if size_gb < 5:
                            return True, 'int4_or_lower'
                        else:
                            return True, 'int8_or_mixed'
            
            return False, None
            
        except Exception as e:
            print(f"Error detecting quantization: {e}")
            return False, None


#
# Configuration Manager
#
class Configurator:

    def __init__(self, config="config.yaml", max_tokens=8192):
        self.config = Config()
        self.config.model = "gpt4-o"
        self.config.MAX_TOKENS = max_tokens
        self.config.temperature = 0
        self.config.heuristicScriptIdentification = False
        self.config.system_prompt= ""
        self.config.answerKey = ""
        self.config.row_format = "#{r} {line}"
        self.config.smells = []
        self.load_smells_config(config)

        self.clients = {}
        self.hf_models = {}
        self.hf_tokenizers = {}
        self.llama_models = {}
        self.mlx_models_loaded = set()
        self.config.tokens = []
        self.model_analyzer = ModelAnalyzer()
        self.debug = False
        self.cacheResp = Cache()
    
    def _smart_load_model(self, model_path: str, device: str = "auto",
                        torch_dtype: str = "auto", local_files_only: bool = False):
        """
        Intelligently load model by analyzing its format and choosing best backend.
        Uses caching to avoid reloading the same model.
        """
        cache_key = f"{model_path}_{device}_{torch_dtype}_{local_files_only}"
        
        # Check if model is already loaded in any cache
        if cache_key in self.hf_models:
            if self.debug:
                print(f"Using cached transformers model: {model_path}")
            return 'transformers', self.hf_models[cache_key], self.hf_tokenizers[cache_key]
        
        if model_path in self.mlx_models_loaded:
            if self.debug:
                print(f"Using cached MLX model: {model_path}")
            return 'mlx', model_path, None
        
        if model_path in self.llama_models:
            if self.debug:
                print(f"Using cached llama.cpp model: {model_path}")
            return 'llama_cpp', self.llama_models[model_path], None
        
        if self.debug:
            print(f"Model not in cache, analyzing and loading: {model_path}")
        
        # If path doesn't exist locally and not local_files_only, try to download
        if not os.path.exists(model_path) and not local_files_only:
            if self.debug:
                print(f"Model path does not exist locally, will download from HuggingFace Hub: {model_path}")
            
            # On Apple Silicon, prefer MLX for much better performance
            if HAS_MLX and sys.platform == 'darwin':
                if self.debug:
                    print("Detected Apple Silicon with MLX available - using MLX backend (much faster!)")
                try:
                    worker = get_mlx_worker()
                    worker.load_model(model_path)
                    self.mlx_models_loaded.add(model_path)
                    return 'mlx', model_path, None
                except Exception as e:
                    if self.debug:
                        print(f"MLX loading failed ({e}), falling back to transformers...")
            
            # Fallback to transformers
            if HAS_TRANSFORMERS:
                if self.debug:
                    print("Using transformers backend for HuggingFace Hub model")
                model, tokenizer = self._load_transformers_model(model_path, device, torch_dtype, local_files_only)
                return 'transformers', model, tokenizer
            else:
                raise ValueError("No suitable backend available")
        
        # Analyze the model
        analysis = self.model_analyzer.analyze_model(model_path)
        if self.debug:
            print("=" * 60)
            print("MODEL ANALYSIS:")
            print(f"  Format: {analysis['format']}")
            print(f"  Quantization: {analysis['quantization']}")
            print(f"  Reason: {analysis['reason']}")
            print(f"  Preferred backends: {analysis['backend_preference']}")
            if 'config_valid' in analysis:
                print(f"  Config valid: {analysis['config_valid']}")
                print(f"  Has quant config: {analysis['has_quant_config']}")
            print("=" * 60)
        
        # Choose backend
        if not analysis['backend_preference']:
            if analysis['format'] == 'unknown' and HAS_TRANSFORMERS:
                if self.debug:
                    print("Unknown format but transformers available, trying transformers backend")
                model, tokenizer = self._load_transformers_model(model_path, device, torch_dtype, local_files_only)
                return 'transformers', model, tokenizer
            raise ValueError(f"No suitable backend found for model format: {analysis['format']}")
        
        # Handle problematic quantization config
        config_info = self.model_analyzer._analyze_config(os.path.join(model_path, 'config.json'))
        
        # If model has custom quantization (bits/group_size) but transformers can't handle it,
        # or if it has incomplete config, prefer MLX or remove the config
        if config_info.get('is_quantized') and config_info.get('quant_method', '').startswith('custom_'):
            if self.debug:
                print(f"Detected custom quantization: {config_info.get('quant_method')}")
            # For custom quantized models, strongly prefer MLX on Apple Silicon
            if HAS_MLX and 'darwin' in sys.platform and 'mlx' in analysis['backend_preference']:
                if self.debug:
                    print("Using MLX for custom quantized model (best compatibility)")
                backend = 'mlx'
            else:
                # Otherwise, remove the problematic config before loading with transformers
                if self.debug:
                    print("Removing custom quantization config for transformers compatibility")
                self._remove_quantization_config(model_path)
                backend = analysis['backend_preference'][0]
        elif config_info.get('needs_removal'):
            if self.debug:
                print("Removing incomplete quantization config")
            self._remove_quantization_config(model_path)
            backend = analysis['backend_preference'][0]
        else:
            backend = analysis['backend_preference'][0]
        
        if self.debug:
            print(f"Selected backend: {backend}")
        
        # Load with appropriate backend
        if backend == 'llama_cpp':
            return 'llama_cpp', self._load_llama_cpp_model(model_path), None
        elif backend == 'mlx':
            worker = get_mlx_worker()
            worker.load_model(model_path)
            self.mlx_models_loaded.add(model_path)
            return 'mlx', model_path, None
        elif backend == 'transformers':
            model, tokenizer = self._load_transformers_model(model_path, device, torch_dtype, local_files_only)
            return 'transformers', model, tokenizer
        else:
            raise ValueError(f"Unsupported backend: {backend}")

    def _remove_quantization_config(self, model_path: str):
        """Remove problematic quantization config from config.json"""
        config_path = os.path.join(model_path, 'config.json')
        
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
            
            if 'quantization_config' in config:
                # Create backup only once
                backup_path = config_path + '.original'
                if not os.path.exists(backup_path):
                    shutil.copy2(config_path, backup_path)
                    if self.debug:
                        print(f"Backed up original config to: {backup_path}")
                
                # Remove the problematic quantization_config
                del config['quantization_config']
                
                # Save the fixed config
                with open(config_path, 'w') as f:
                    json.dump(config, f, indent=2)

                if self.debug:
                    print("Removed quantization_config from config.json")
        except Exception as e:
            if self.debug:
                print(f"Warning: Could not remove quantization config: {e}")
    
    def _load_llama_cpp_model(self, model_path: str):
        """Load GGUF model with llama.cpp"""
        if not HAS_LLAMA_CPP:
            raise ImportError("llama-cpp-python not installed. Install with: pip install llama-cpp-python")
        
        if model_path not in self.llama_models:
            gguf_files = [f for f in os.listdir(model_path) if f.endswith('.gguf')]
            if not gguf_files:
                raise ValueError(f"No GGUF file found in {model_path}")
            
            gguf_path = os.path.join(model_path, gguf_files[0])
            if self.debug:
                print(f"Loading GGUF: {gguf_path}")
            
            n_gpu_layers = -1 if torch.cuda.is_available() else 0
            
            model = Llama(
                model_path=gguf_path,
                n_gpu_layers=n_gpu_layers,
                n_ctx=self.config.MAX_TOKENS,
                verbose=False,
                logits_all=True
            )
            
            self.llama_models[model_path] = model
        
        return self.llama_models[model_path]

    def _load_transformers_model(self, model_path: str, device: str = "auto",
                                torch_dtype: str = "auto", local_files_only: bool = False):
        """Load model with transformers"""
        if not HAS_TRANSFORMERS:
            raise ImportError("transformers not installed")
        
        cache_key = f"{model_path}_{device}_{torch_dtype}_{local_files_only}"
        
        if cache_key not in self.hf_models:
            if self.debug:
                print(f"Loading with transformers: {model_path}")
            
            tokenizer = AutoTokenizer.from_pretrained(
                model_path,
                trust_remote_code=True,
                local_files_only=local_files_only
            )
            
            if torch_dtype == "auto":
                dtype = torch.float16 if torch.cuda.is_available() else torch.float32
            elif torch_dtype == "float16":
                dtype = torch.float16
            elif torch_dtype == "bfloat16":
                dtype = torch.bfloat16
            else:
                dtype = torch.float32
            
            model_kwargs = {
                "torch_dtype": dtype,
                "device_map": device,
                "trust_remote_code": True,
                "local_files_only": local_files_only,
                "low_cpu_mem_usage": True
            }
            
            if 'phi' in model_path.lower():
                if self.debug:
                    print("Detected Phi model, using eager attention implementation...")
                model_kwargs["attn_implementation"] = "eager"
            
            if torch.backends.mps.is_available():
                if self.debug:
                    print("Detected Apple Silicon (MPS). Consider using MLX for much better performance!")
            
            if not torch.cuda.is_available() and not torch.backends.mps.is_available():
                if self.debug:
                    print("Warning: Running on CPU. Generation will be VERY slow.")
                model_kwargs["torch_dtype"] = torch.float32
            
            try:
                model = AutoModelForCausalLM.from_pretrained(
                    model_path,
                    **model_kwargs
                )
            except Exception as e:
                if "attn_implementation" in model_kwargs:
                    if self.debug:
                        print(f"Failed with eager attention, retrying without it...")
                    del model_kwargs["attn_implementation"]
                    model = AutoModelForCausalLM.from_pretrained(
                        model_path,
                        **model_kwargs
                    )
                else:
                    raise e
            
            model.eval()
            self.hf_models[cache_key] = model
            self.hf_tokenizers[cache_key] = tokenizer
            
            if hasattr(model, 'hf_device_map'):
                if self.debug:
                    print(f"Model loaded on devices: {model.hf_device_map}")
            else:
                if self.debug:
                    print(f"Model loaded on: {model.device}")
        else:
            if self.debug:
                print(f"Using cached transformers model: {cache_key}")
        
        return self.hf_models[cache_key], self.hf_tokenizers[cache_key]
    
    def _llama_cpp_inference(self, model, system_prompt: str, user_prompt: str,
                            tokens: list, temperature: float):
        """Generate with llama.cpp"""
        prompt = f"<|im_start|>system\n{system_prompt}<|im_end|>\n<|im_start|>user\n{user_prompt}<|im_end|>\n<|im_start|>assistant\n"
        
        output = model(
            prompt,
            max_tokens=self.config.MAX_TOKENS,
            temperature=temperature if temperature > 0 else 0.1,
            echo=False,
            logprobs=1
        )
        
        generated_text = output['choices'][0]['text']
        
        log_probs = []
        if 'logprobs' in output['choices'][0]:
            logprobs_data = output['choices'][0]['logprobs']
            if logprobs_data and 'token_logprobs' in logprobs_data:
                log_probs = [lp for lp in logprobs_data['token_logprobs'] if lp is not None]
        
        confidence = np.exp(np.mean(log_probs)) if log_probs else 0.0
        
        tokens.append({
            "input": len(model.tokenize(prompt.encode('utf-8'))),
            "output": len(model.tokenize(generated_text.encode('utf-8'))),
            "confidence": confidence
        })
        
        return generated_text, confidence

    def _mlx_inference(self, model_path, system_prompt: str, user_prompt: str,
                      tokens: list, temperature: float):
        """Generate with MLX using dedicated worker"""
        worker = get_mlx_worker()
        
        result = worker.infer(
            model_path=model_path,
            system_prompt=system_prompt,
            user_prompt=user_prompt,
            temperature=temperature,
            max_tokens=self.config.MAX_TOKENS
        )
        
        generated_text = result['text']
        confidence = result['confidence']
        
        if self.debug:
            if result['log_probs']:
                print(f"MLX log probs sample (first 10): {result['log_probs']}")
            else:
                print("Warning: Could not extract log probabilities from MLX")
        
        tokens.append({
            "input": result['input_tokens'],
            "output": result['output_tokens'],
            "confidence": confidence
        })
        
        return generated_text, confidence

    def _transformers_inference(self, model, tokenizer, system_prompt: str, user_prompt: str,
                            tokens: list, temperature: float):
        """Generate with transformers"""
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ]
        
        text = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
        inputs = tokenizer(text, return_tensors="pt")
        
        if hasattr(model, 'hf_device_map'):
            first_device = list(model.hf_device_map.values())[0]
            inputs = {k: v.to(first_device) for k, v in inputs.items()}
        else:
            inputs = {k: v.to(model.device) for k, v in inputs.items()}
        
        input_length = inputs['input_ids'].shape[1]
        
        max_new_tokens = self.config.MAX_TOKENS  
        
        generation_kwargs = {
            'max_new_tokens': max_new_tokens,
            'temperature': temperature if temperature > 0 else 1.0,
            'do_sample': temperature > 0,
            'return_dict_in_generate': True,
            'output_scores': True,
            'pad_token_id': tokenizer.eos_token_id if tokenizer.eos_token_id is not None else tokenizer.pad_token_id
        }
        
        model_name = model.config._name_or_path if hasattr(model.config, '_name_or_path') else ""
        
        use_cache = True
        if 'phi' in model_name.lower():
            if self.debug:
                print("Phi model detected - attempting generation with cache...")
        
        generation_kwargs['use_cache'] = use_cache

        if self.debug:
            print(f"Generating up to {max_new_tokens} tokens...", end='', flush=True)
        start_time = time.time()
        
        try:
            with torch.no_grad():
                outputs = model.generate(
                    **inputs,
                    **generation_kwargs
                )
            elapsed = time.time() - start_time
            if self.debug:
                print(f" Done! ({elapsed:.2f}s)")
        except (AttributeError, TypeError) as e:
            if 'seen_tokens' in str(e) or 'DynamicCache' in str(e):
                if self.debug:
                    print(f"\nCache issue detected, retrying without cache (will be slower)...")
                generation_kwargs['use_cache'] = False
                start_time = time.time()
                with torch.no_grad():
                    outputs = model.generate(
                        **inputs,
                        **generation_kwargs
                    )
                elapsed = time.time() - start_time
                if self.debug:
                    print(f" Done! ({elapsed:.2f}s)")
            else:
                if self.debug:
                    print(" Failed!")
                raise e
        except KeyboardInterrupt:
            if self.debug:
                print("\nGeneration interrupted by user")
            raise
        
        generated_ids = outputs.sequences[0][input_length:]
        generated_text = tokenizer.decode(generated_ids, skip_special_tokens=True)
        
        log_probs = []
        if hasattr(outputs, 'scores') and outputs.scores:
            for i, score in enumerate(outputs.scores):
                if i < len(generated_ids):
                    token_log_probs = torch.nn.functional.log_softmax(score[0], dim=-1)
                    generated_token_id = generated_ids[i]
                    token_log_prob = token_log_probs[generated_token_id].item()
                    log_probs.append(token_log_prob)
        
        confidence = np.exp(np.mean(log_probs)) if log_probs else 0.0
        
        tokens.append({
            "input": input_length,
            "output": len(generated_ids),
            "confidence": confidence,
            "generation_time": elapsed if 'elapsed' in locals() else 0
        })
        
        return generated_text, confidence

    def _hf_inference(self, system_prompt: str, user_prompt: str, model_path: str,
                    tokens: list, temperature: float, device: str = "auto",
                    torch_dtype: str = "auto", local_files_only: bool = False):
        """Smart inference with automatic backend selection"""
        
        if not model_path:
            raise ValueError("model_path cannot be None or empty")
        
        backend, model, tokenizer = self._smart_load_model(model_path, device, torch_dtype, local_files_only)
        
        if backend == 'llama_cpp':
            return self._llama_cpp_inference(model, system_prompt, user_prompt, tokens, temperature)
        elif backend == 'mlx':
            # For MLX, model is actually the model_path
            return self._mlx_inference(model, system_prompt, user_prompt, tokens, temperature)
        elif backend == 'transformers':
            return self._transformers_inference(model, tokenizer, system_prompt, user_prompt, tokens, temperature)
        else:
            raise ValueError(f"Unknown backend: {backend}")
    
    def _getClient(self, model: str):
        client = None
        client_type = 0
        
        if self.config.use_huggingface:
            client_type = 4
            return client_type, None
        
        if model.startswith("gpt"):
            client_type = 1
            m = model + self.config.url if self.config.url else ""
            if m not in self.clients:
                if self.config.url:
                    client = OpenAI(base_url=self.config.url, api_key="not-needed")
                else:
                    client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
                self.clients[m] = client
            else:
                client = self.clients.get(m)
        elif model.startswith("claude"):
            client_type = 0
            if model not in self.clients:
                client = anthropic.Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))
                self.clients[model] = client
            else:
                client = self.clients.get(model)
        else:
            client_type = 3
            m = model + (self.config.url if self.config.url else "")
            if m not in self.clients:
                client = OpenAI(base_url=self.config.url, api_key="not-needed")
                self.clients[m] = client
            else:
                client = self.clients.get(m)
        return client_type, client
    
    def safeCache(self,key,value):
        res = {}
        res['result'] = value[0]
        res['confidence'] = value[1]
        self.cacheResp.set(key,res)

    def llm_call(self, system_prompt: str, user_prompt: str, model: str,
                tokens: list, temperature: float, backoff_factor=1.0, use_cache = False,
                return_confidence: bool = True):
        client_type, client = self._getClient(model)

        key = system_prompt + user_prompt + model
        
        if use_cache:
            res = self.cacheResp.get(key)
            if res:
                return res['result'], res['confidence']
            

        if client_type == 4:
            model_path = self.config.hf_model_path if self.config.hf_model_path else model
            device = self.config.device
            torch_dtype = self.config.torch_dtype
            local_files_only = self.config.local_files_only
            
            try:
                generated_text, confidence = self._hf_inference(
                    system_prompt, user_prompt, model_path, tokens,
                    temperature, device, torch_dtype, local_files_only
                )
                self.safeCache(key,(generated_text, confidence))
                return generated_text, confidence
            except Exception as e:
                print("An error occurred during inference:")
                print(traceback.format_exc())
                raise e
        
        # Handle API-based models
        for attempt in range(3):
            try:
                cleaned_text = None
                confidence = None
                
                if client_type == 1 or client_type == 3:
                    msg = [{"role": "system", "content": system_prompt}]
                    msg.append({"role": "user", "content": user_prompt})
                    
                    extra_params = {}
                    if return_confidence and client_type == 1:
                        extra_params['logprobs'] = True
                    
                    response = client.chat.completions.create(
                        model=model,
                        messages=msg,
                        max_tokens=self.config.MAX_TOKENS,
                        temperature=temperature,
                        timeout=600.0,
                        **extra_params
                    )
                    cleaned_text = response.choices[0].message.content
                    
                    token_info = {
                        "input": response.usage.prompt_tokens,
                        "output": response.usage.completion_tokens
                    }
                    
                    if return_confidence and hasattr(response.choices[0], 'logprobs') and response.choices[0].logprobs:
                        log_probs = [token.logprob for token in response.choices[0].logprobs.content]
                        confidence = np.exp(np.mean(log_probs)) if log_probs else 0.0
                        token_info['confidence'] = confidence
                    
                    tokens.append(token_info)
                    
                elif client_type == 0:
                    msg = []
                    msg.append({"role": "user", "content": user_prompt})
                    response = client.messages.create(
                        model=model,
                        max_tokens=self.config.MAX_TOKENS,
                        system=system_prompt,
                        messages=msg,
                        temperature=temperature
                    )
                    cleaned_text = response.content[0].text
                    tokens.append({
                        "input": response.usage.input_tokens,
                        "output": response.usage.output_tokens
                    })
                
                self.safeCache(key,(cleaned_text, confidence))
                return cleaned_text, confidence
                
            except Exception as e:
                print("An error occurred during processing...")
                print(traceback.format_exc())
                wait = backoff_factor * (2 ** attempt)
                time.sleep(wait)
        
        raise Exception(f"Max retries exceeded {model}")

    def load_smells_config(self, config_file):
        with open(config_file, 'r', encoding='utf-8') as file:
            config_data = yaml.safe_load(file)
        
        self.config.smells = []
        
        conf = config_data.get('config', [])
        for c in conf:
            self.config.model = c.get('model', "gpt4-o")
            self.config.url = c.get('url', "")
            self.config.use_huggingface = c.get('use_huggingface', False)
            self.config.hf_model_path = c.get('hf_model_path', None)
            self.config.device = c.get('device', 'auto')
            self.config.torch_dtype = c.get('torch_dtype', 'auto')
            self.config.local_files_only = c.get('local_files_only', False)
            self.config.backend = c.get('backend', 'auto')
            if 'maxTokens' in c:
                self.config.MAX_TOKENS = c.get('maxTokens')
            if 'temperature' in c:
                self.config.temperature = c.get('temperature')
            self.config.row_format = c.get('rowFormat', "#{r} {line}")
            self.config.answerKey = c.get('answerKey', "ANSWER: ")
            self.config.retries = c.get('retries', 4)
            self.config.cache = c.get('cache', False)
            self.config.heuristicScriptIdentification = c.get('heuristicScriptIdentification', False)
            self.config.scriptTypePrompt = c.get('scriptTypePrompt', '')
            self.config.system_prompt = c.get('systemPrompt', "You are an expert of IaC Security.")
        
        for smell in config_data.get('smells', []):
            self.config.smells.append({
                'name': smell.get('name'),
                'prompt': smell.get('prompt'),
                'cache': smell.get('cache', self.config.cache),
                'temperature': smell.get('temperature', self.config.temperature),
                'severity': smell.get('severity'),
                'description': smell.get('description'),
                'model': smell.get('model', self.config.model),
                'url': smell.get('url', ""),
                'use_huggingface': smell.get('use_huggingface', self.config.use_huggingface),
                'hf_model_path': smell.get('hf_model_path', self.config.hf_model_path),
                'device': smell.get('device', self.config.device),
                'torch_dtype': smell.get('torch_dtype', self.config.torch_dtype),
                'local_files_only': smell.get('local_files_only', self.config.local_files_only),
                'backend': smell.get('backend', self.config.backend),
                'answerKey': smell.get('answerKey', self.config.answerKey),
                'analysisStart': smell.get('analysisStart', 'REASON: '),
                'analysisEnd': smell.get('analysisEnd', 'VERIFICATION:'),
                'exclude': smell.get('exclude', ''),
                'onlyCheckRegExpr': smell.get('onlyCheckRegExpr', 'No'),
                'prefilterRegEx': smell.get('prefilterRegEx', '').strip(),
                'insideRegEx': smell.get('insideRegEx', 'No').strip(),
                'dontAnalyzeRegEx': smell.get('dontAnalyzeRegEx', '')
            })
        
        return self.config.smells

    def getSmellsByNames(self, names):
        return [s for s in self.config.smells if s['name'] in names]

    def getSmellNames(self):
        return [s['name'] for s in self.config.smells]

    def getSmellConfig(self, name):
        return next((s for s in self.config.smells if s['name'].lower() == name.lower()), None)
    
    def clear_model_cache(self):
        self.hf_models.clear()
        self.hf_tokenizers.clear()
        self.llama_models.clear()
        self.mlx_models_loaded.clear()
        if torch.cuda.is_available():
            torch.cuda.empty_cache()
        if self.debug:
            print("Model cache cleared")
    
    @property
    def scriptTypePrompt(self):
        return self.config.scriptTypePrompt

    @property
    def model(self):
        return self.config.model
    
    @property
    def MAX_TOKENS(self):
        return self.config.MAX_TOKENS
    
    @property
    def system_prompt(self):
        return self.config.system_prompt

    @property
    def answerKey(self):
        return self.config.answerKey

    @property
    def row_format(self):
        return self.config.row_format

    @property
    def smells(self):
        return self.config.smells

    @property
    def tokens(self):
        return self.config.tokens

    @property
    def retries(self):
        return self.config.retries
    
    @property
    def heuristicScriptIdentification(self):
        return self.config.heuristicScriptIdentification

    @property
    def url(self):
        return self.config.url

    @property
    def use_huggingface(self):
        return self.config.use_huggingface

    @property
    def hf_model_path(self):
        return self.config.hf_model_path

    @property
    def device(self):
        return self.config.device

    @property
    def torch_dtype(self):
        return self.config.torch_dtype

    @property
    def local_files_only(self):
        return self.config.local_files_only

    @property
    def backend(self):
        return self.config.backend


if __name__ == '__main__':
    print("Smart Model Loader - Auto-detecting format and backend")
    print(f"Available backends: transformers={HAS_TRANSFORMERS}, llama.cpp={HAS_LLAMA_CPP}, MLX={HAS_MLX}")
    print()
    
    c = Configurator("config.yaml")
    c.debug = True
    c.config.use_huggingface = True
    c.config.hf_model_path = "./models/Qwen2.5-32B-Instruct"
    c.config.local_files_only = True
    
    result, confidence = c.llm_call(
        system_prompt="You are a helpful assistant",
        user_prompt="What is AI?",
        model="Qwen/Qwen2.5-32B-Instruct",
        tokens=c.tokens,
        temperature=0.7,
        return_confidence=True
    )
    print("\nGenerated text:", result)
    print(f"Confidence: {confidence:.4f}")