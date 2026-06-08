import os
import numpy as np
from fuzzywuzzy import fuzz
from transformers import AutoTokenizer, AutoModel
import torch
from sklearn.metrics.pairwise import cosine_similarity
import torch.nn.functional as F

# Initialize CodeBERT
tokenizer = AutoTokenizer.from_pretrained("microsoft/codebert-base")
model = AutoModel.from_pretrained("microsoft/codebert-base")

def get_codebert_embedding(code_text):
    """Get CodeBERT embedding for a code text"""
    # Tokenize the text
    inputs = tokenizer(code_text, return_tensors="pt", truncation=True, 
                      padding=True, max_length=512)
    
    # Get embeddings
    with torch.no_grad():
        outputs = model(**inputs)
        # Use [CLS] token as code representation
        embeddings = outputs.last_hidden_state[:, 0, :].numpy()
    
    return embeddings

def calcola_token_sort_ratio(testo1, testo2):
    """Calculate token sort ratio using fuzzywuzzy"""
    return fuzz.token_sort_ratio(testo1, testo2) / 100.0  # Normalize to 0-1

def calcola_cosine_similarity(embedding1, embedding2):
    """Calculate cosine similarity between two embeddings"""
    return cosine_similarity(embedding1.reshape(1, -1), 
                           embedding2.reshape(1, -1))[0][0]

def check_overlap_with_oracle(example_text, oracle_dataset_path, 
                             token_threshold=0.3, cosine_threshold=0.4):
    """
    Check if an example overlaps with the oracle dataset
    
    Args:
        example_text: The example text to check
        oracle_dataset_path: Path to oracle dataset
        token_threshold: Threshold for token_sort_ratio (default 0.3)
        cosine_threshold: Threshold for cosine similarity (default 0.4)
    
    Returns:
        tuple: (has_overlap, max_token_ratio, max_cosine_sim, overlap_file)
    """
    
    example_text_clean = example_text.lower().strip()
    example_embedding = get_codebert_embedding(example_text)
    
    max_token_ratio = 0.0
    max_cosine_sim = 0.0
    overlap_file = None
    has_overlap = False
    
    print(f"Checking overlap for example with {len(example_text)} characters...")
    
    # Scan all files in oracle dataset
    file_count = 0
    for root, dirs, files in os.walk(oracle_dataset_path):
        for nome_file in files:
            if nome_file.endswith(('.rb', '.py', '.js', '.java', '.cpp', '.c')):  # Common code extensions
                file_count += 1
                percorso_file = os.path.join(root, nome_file)
                
                try:
                    with open(percorso_file, 'r', encoding='utf-8', errors='ignore') as f:
                        oracle_content = f.read().lower().strip()
                        
                        if len(oracle_content) == 0:
                            continue
                        
                        # Calculate token sort ratio
                        token_ratio = calcola_token_sort_ratio(example_text_clean, oracle_content)
                        
                        # Calculate cosine similarity only if necessary (for efficiency)
                        cosine_sim = 0.0
                        if token_ratio > token_threshold * 0.5:  # Pre-filter for efficiency
                            oracle_embedding = get_codebert_embedding(oracle_content)
                            cosine_sim = calcola_cosine_similarity(example_embedding, oracle_embedding)
                        
                        # Update maximums
                        if token_ratio > max_token_ratio:
                            max_token_ratio = token_ratio
                        
                        if cosine_sim > max_cosine_sim:
                            max_cosine_sim = cosine_sim
                        
                        # Check if thresholds are exceeded
                        if token_ratio > token_threshold or cosine_sim > cosine_threshold:
                            has_overlap = True
                            overlap_file = nome_file
                            print(f"OVERLAP DETECTED with {nome_file}:")
                            print(f"  Token sort ratio: {token_ratio:.3f}")
                            print(f"  Cosine similarity: {cosine_sim:.3f}")
                            print("-" * 50)
                            break
                        
                        # Progress every 100 files
                        if file_count % 100 == 0:
                            print(f"Processed {file_count} files... Max ratios: {max_token_ratio:.3f}, {max_cosine_sim:.3f}")
                
                except Exception as e:
                    print(f"Error processing {nome_file}: {e}")
                    continue
        
        if has_overlap:
            break
    
    print(f"Check completed on {file_count} files.")
    return has_overlap, max_token_ratio, max_cosine_sim, overlap_file

def filter_dataset_examples(examples_path, oracle_dataset_path, 
                          output_path=None, token_threshold=0.3, cosine_threshold=0.4):
    """
    Filter a dataset by removing examples that overlap with oracle dataset
    
    Args:
        examples_path: Path to examples to filter
        oracle_dataset_path: Path to oracle dataset
        output_path: Path to save filtered examples (optional)
        token_threshold: Threshold for token_sort_ratio
        cosine_threshold: Threshold for cosine similarity
    """
    
    filtered_examples = []
    overlap_count = 0
    total_count = 0
    
    # Read examples (assuming they are in text files)
    for root, dirs, files in os.walk(examples_path):
        for nome_file in files:
            if nome_file.endswith('.txt'):  # or other appropriate extension
                total_count += 1
                percorso_file = os.path.join(root, nome_file)
                
                with open(percorso_file, 'r', encoding='utf-8', errors='ignore') as f:
                    example_text = f.read()
                
                print(f"\n=== Checking example {total_count}: {nome_file} ===")
                
                has_overlap, max_token, max_cosine, overlap_file = check_overlap_with_oracle(
                    example_text, oracle_dataset_path, token_threshold, cosine_threshold
                )
                
                if has_overlap:
                    overlap_count += 1
                    print(f"EXCLUDED: {nome_file} (overlap with {overlap_file})")
                else:
                    filtered_examples.append((nome_file, example_text))
                    print(f"INCLUDED: {nome_file} (max token: {max_token:.3f}, max cosine: {max_cosine:.3f})")
    
    print(f"\n=== FINAL RESULTS ===")
    print(f"Total examples processed: {total_count}")
    print(f"Examples with overlap: {overlap_count}")
    print(f"Filtered examples (valid): {len(filtered_examples)}")
    print(f"Percentage retained: {len(filtered_examples)/total_count*100:.1f}%")
    
    # Save filtered examples if specified
    if output_path:
        os.makedirs(output_path, exist_ok=True)
        for nome_file, contenuto in filtered_examples:
            output_file = os.path.join(output_path, nome_file)
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(contenuto)
        print(f"Filtered examples saved to: {output_path}")
    
    return filtered_examples

# Usage example
if __name__ == "__main__":
    # Single example
    testo_esempio = """
    template '/path/to/config/file' do
       source 'config.erb'
       variables(
         :dbuser => node['wordpress']['db']['dbuser'],
         :dbpassword => node['wordpress']['db']['dbpassword']
       )
     end
     mysql_database_user node['wordpress']['db']['dbuser'] do
       password node['wordpress']['db']['dbpassword']
       action :create
     end
    """
    
    cartella_oracle = '../glitch-datasets/chef/oracle-dataset'
    
    # Check single example
    has_overlap, max_token, max_cosine, overlap_file = check_overlap_with_oracle(
        testo_esempio, cartella_oracle
    )
    
    print(f"\n=== RESULT ===")
    print(f"Overlap detected: {has_overlap}")
    print(f"Max token sort ratio: {max_token:.3f}")
    print(f"Max cosine similarity: {max_cosine:.3f}")
    if overlap_file:
        print(f"File with overlap: {overlap_file}")
    
    # To filter an entire dataset:
    # examples_path = 'path/to/your/examples'
    # filtered = filter_dataset_examples(examples_path, cartella_oracle, 'output/filtered_examples')