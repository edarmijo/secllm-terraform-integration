import pickle
import hashlib
import time
import atexit
import signal
import sys
import yaml
from typing import Any, Optional, Dict
from pathlib import Path
from dataclasses import dataclass
from datetime import datetime, timedelta


@dataclass
class CacheEntry:
    """Represents a single cache entry with its value and timestamp."""
    value: Any
    timestamp: float


class CacheConfig:
    """Configuration class for Cache settings loaded from YAML file."""
    
    def __init__(self, config_file: str = "cache_config.yaml"):
        """
        Initialize configuration from YAML file.
        
        Args:
            config_file: Path to the YAML configuration file
        """
        self.config_file = Path(config_file)
        self.config = self._load_config()
    
    def _load_config(self) -> Dict[str, Any]:
        """
        Load configuration from YAML file.
        
        Returns:
            Dictionary containing configuration settings
        """
        # Default configuration
        default_config = {
            'cache_file': 'cache.pkl',
            'ttl_seconds': -1,
            'auto_cleanup': True,
            'cleanup_interval': 300,  # seconds
            'max_entries': -1,  # -1 means unlimited
            'compression': False,
            'verbose': True
        }
        
        # If config file doesn't exist, create it with defaults
        if not self.config_file.exists():
            print(f"Configuration file not found. Creating default config at {self.config_file}")
            self._create_default_config(default_config)
            return default_config
        
        # Load configuration from file
        try:
            with open(self.config_file, 'r') as f:
                loaded_config = yaml.safe_load(f)
                
            if loaded_config is None:
                loaded_config = {}
            
            # Merge with defaults (in case some keys are missing)
            config = {**default_config, **loaded_config}
            
            if config.get('verbose', True):
                print(f"Configuration loaded from {self.config_file}")
            
            return config
            
        except Exception as e:
            print(f"Error loading configuration: {e}. Using defaults.")
            return default_config
    
    def _create_default_config(self, config: Dict[str, Any]):
        """
        Create a default configuration file with comments.
        
        Args:
            config: Configuration dictionary to save
        """
        yaml_content = """# Cache Configuration File

# Path to the cache persistence file
cache_file: cache.pkl

# Time To Live (TTL) for cache entries in seconds
# -1 means unlimited duration
ttl_seconds: -1

# Enable automatic cleanup of expired entries
auto_cleanup: true

# Interval in seconds between automatic cleanup operations
# Only used if auto_cleanup is true
cleanup_interval: 300

# Maximum number of entries in cache
# -1 means unlimited
# When limit is reached, oldest entries are removed (LRU)
max_entries: -1

# Enable compression for cache file (saves disk space)
compression: false

# Enable verbose logging
verbose: true
"""
        try:
            with open(self.config_file, 'w') as f:
                f.write(yaml_content)
            print(f"Default configuration created at {self.config_file}")
        except Exception as e:
            print(f"Error creating default configuration: {e}")
    
    def get(self, key: str, default: Any = None) -> Any:
        """
        Get a configuration value.
        
        Args:
            key: Configuration key
            default: Default value if key not found
            
        Returns:
            Configuration value or default
        """
        return self.config.get(key, default)
    
    def reload(self):
        """Reload configuration from file."""
        self.config = self._load_config()


class Cache:
    """
    A cache manager that stores objects using hashed string keys.
    Configuration is loaded from a YAML file.
    
    Features:
    - YAML-based configuration
    - Automatic persistence to disk
    - Configurable TTL (Time To Live)
    - Automatic cleanup of expired entries
    - Maximum entries limit (LRU eviction)
    - Graceful shutdown handling (including CTRL+C)
    """
    
    def __init__(self, config_file: str = "cache_config.yaml"):
        """
        Initialize the cache manager with configuration from YAML file.
        
        Args:
            config_file: Path to the YAML configuration file
        """
        # Load configuration
        self.config = CacheConfig(config_file)
        
        # Initialize cache properties from config
        self.cache_file = Path(self.config.get('cache_file', 'cache.pkl'))
        self.ttl_seconds = self.config.get('ttl_seconds', -1)
        self.auto_cleanup = self.config.get('auto_cleanup', True)
        self.cleanup_interval = self.config.get('cleanup_interval', 300)
        self.max_entries = self.config.get('max_entries', -1)
        self.compression = self.config.get('compression', False)
        self.verbose = self.config.get('verbose', True)
        
        self._cache: Dict[str, CacheEntry] = {}
        self._last_cleanup = time.time()
        
        # Load existing cache from disk
        self._load_from_disk()
        
        # Register cleanup handlers for graceful shutdown
        self._register_shutdown_handlers()
        
        self._log(f"Cache initialized with TTL={self.ttl_seconds}s, max_entries={self.max_entries}")
    
    def _log(self, message: str):
        """
        Log a message if verbose mode is enabled.
        
        Args:
            message: Message to log
        """
        if self.verbose:
            print(f"[Cache] {message}")
    
    def _register_shutdown_handlers(self):
        """Register handlers to save cache on program exit or interruption."""
        # Handle normal exit
        atexit.register(self._save_to_disk)
        
        # Handle CTRL+C (SIGINT) and termination (SIGTERM)
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle interrupt signals by saving cache and exiting."""
        self._log("Received interrupt signal. Saving cache...")
        self._save_to_disk()
        sys.exit(0)
    
    def _generate_key(self, input_string: str) -> str:
        """
        Generate a hash key from the input string.
        
        Args:
            input_string: The string to hash
            
        Returns:
            SHA-256 hash of the input string
        """
        return hashlib.sha256(input_string.encode()).hexdigest()
    
    def _is_expired(self, entry: CacheEntry) -> bool:
        """
        Check if a cache entry has expired.
        
        Args:
            entry: The cache entry to check
            
        Returns:
            True if the entry has expired, False otherwise
        """
        if self.ttl_seconds == -1:
            return False
        
        current_time = time.time()
        age = current_time - entry.timestamp
        return age > self.ttl_seconds
    
    def _cleanup_expired(self):
        """Remove all expired entries from the cache."""
        if self.ttl_seconds == -1:
            return
        
        expired_keys = [
            key for key, entry in self._cache.items() 
            if self._is_expired(entry)
        ]
        
        for key in expired_keys:
            del self._cache[key]
        
        if expired_keys:
            self._log(f"Cleaned up {len(expired_keys)} expired cache entries")
    
    def _enforce_max_entries(self):
        """Enforce maximum entries limit by removing oldest entries (LRU)."""
        if self.max_entries == -1:
            return
        
        if len(self._cache) <= self.max_entries:
            return
        
        # Sort entries by timestamp (oldest first)
        sorted_entries = sorted(
            self._cache.items(),
            key=lambda x: x[1].timestamp
        )
        
        # Calculate how many entries to remove
        entries_to_remove = len(self._cache) - self.max_entries
        
        # Remove oldest entries
        for key, _ in sorted_entries[:entries_to_remove]:
            del self._cache[key]
        
        self._log(f"Removed {entries_to_remove} oldest entries to enforce max_entries limit")
    
    def _auto_cleanup_check(self):
        """Check if automatic cleanup should run based on interval."""
        if not self.auto_cleanup:
            return
        
        current_time = time.time()
        if current_time - self._last_cleanup >= self.cleanup_interval:
            self._cleanup_expired()
            self._last_cleanup = current_time
    
    def set(self, key_string: str, value: Any) -> str:
        """
        Store a value in the cache.
        
        Args:
            key_string: The string to use as key (will be hashed)
            value: The object to store
            
        Returns:
            The hash key used to store the value
        """
        # Perform automatic cleanup check
        self._auto_cleanup_check()
        
        key = self._generate_key(key_string)
        entry = CacheEntry(value=value, timestamp=time.time())
        self._cache[key] = entry
        
        # Enforce max entries limit
        self._enforce_max_entries()
        
        return key
    
    def get(self, key_string: str) -> Optional[Any]:
        """
        Retrieve a value from the cache.
        
        Args:
            key_string: The string key (will be hashed)
            
        Returns:
            The cached object if found and not expired, None otherwise
        """
        # Perform automatic cleanup check
        self._auto_cleanup_check()
        
        key = self._generate_key(key_string)
        entry = self._cache.get(key)
        
        if entry is None:
            return None
        
        # Check if entry has expired
        if self._is_expired(entry):
            del self._cache[key]
            return None
        
        # Update timestamp for LRU (optional: uncomment to update access time)
        # entry.timestamp = time.time()
        
        return entry.value
    
    def exists(self, key_string: str) -> bool:
        """
        Check if a key exists in the cache and is not expired.
        
        Args:
            key_string: The string key to check
            
        Returns:
            True if the key exists and is valid, False otherwise
        """
        return self.get(key_string) is not None
    
    def delete(self, key_string: str) -> bool:
        """
        Delete a specific entry from the cache.
        
        Args:
            key_string: The string key to delete
            
        Returns:
            True if the key was found and deleted, False otherwise
        """
        key = self._generate_key(key_string)
        if key in self._cache:
            del self._cache[key]
            return True
        return False
    
    def clear(self):
        """Clear all entries from the cache."""
        self._cache.clear()
        self._log("Cache cleared")
    
    def _save_to_disk(self):
        """Save the current cache to disk."""
        try:
            # Clean up expired entries before saving
            self._cleanup_expired()
            
            data = {
                'cache': self._cache,
                'ttl_seconds': self.ttl_seconds,
                'saved_at': time.time()
            }
            
            with open(self.cache_file, 'wb') as f:
                if self.compression:
                    import gzip
                    compressed_data = gzip.compress(pickle.dumps(data))
                    f.write(compressed_data)
                else:
                    pickle.dump(data, f)
            
            self._log(f"Cache saved to {self.cache_file} ({len(self._cache)} entries)")
        except Exception as e:
            self._log(f"Error saving cache to disk: {e}")
    
    def _load_from_disk(self):
        """Load cache from disk if the file exists."""
        if not self.cache_file.exists():
            self._log("No existing cache file found. Starting with empty cache.")
            return
        
        try:
            with open(self.cache_file, 'rb') as f:
                if self.compression:
                    import gzip
                    compressed_data = f.read()
                    data = pickle.loads(gzip.decompress(compressed_data))
                else:
                    data = pickle.load(f)
            
            self._cache = data.get('cache', {})
            
            # Clean up expired entries after loading
            self._cleanup_expired()
            
            saved_at = data.get('saved_at', 0)
            saved_time = datetime.fromtimestamp(saved_at).strftime('%Y-%m-%d %H:%M:%S')
            self._log(f"Cache loaded from {self.cache_file} with {len(self._cache)} entries (saved at {saved_time})")
        except Exception as e:
            self._log(f"Error loading cache from disk: {e}")
            self._cache = {}
    
    def save(self):
        """Manually save the cache to disk."""
        self._save_to_disk()
    
    def reload_config(self):
        """Reload configuration from YAML file."""
        old_config = {
            'ttl_seconds': self.ttl_seconds,
            'max_entries': self.max_entries
        }
        
        self.config.reload()
        
        self.ttl_seconds = self.config.get('ttl_seconds', -1)
        self.auto_cleanup = self.config.get('auto_cleanup', True)
        self.cleanup_interval = self.config.get('cleanup_interval', 300)
        self.max_entries = self.config.get('max_entries', -1)
        self.compression = self.config.get('compression', False)
        self.verbose = self.config.get('verbose', True)
        
        self._log("Configuration reloaded")
        
        # If TTL changed, cleanup might be needed
        if old_config['ttl_seconds'] != self.ttl_seconds:
            self._cleanup_expired()
        
        # If max_entries decreased, enforce limit
        if old_config['max_entries'] != self.max_entries:
            self._enforce_max_entries()
    
    def get_stats(self) -> Dict[str, Any]:
        """
        Get statistics about the current cache.
        
        Returns:
            Dictionary containing cache statistics
        """
        total_entries = len(self._cache)
        expired_entries = sum(1 for entry in self._cache.values() if self._is_expired(entry))
        
        if self._cache:
            oldest_entry = min(self._cache.values(), key=lambda x: x.timestamp)
            newest_entry = max(self._cache.values(), key=lambda x: x.timestamp)
            oldest_age = time.time() - oldest_entry.timestamp
            newest_age = time.time() - newest_entry.timestamp
        else:
            oldest_age = 0
            newest_age = 0
        
        return {
            'total_entries': total_entries,
            'active_entries': total_entries - expired_entries,
            'expired_entries': expired_entries,
            'ttl_seconds': self.ttl_seconds,
            'max_entries': self.max_entries,
            'auto_cleanup': self.auto_cleanup,
            'cache_file': str(self.cache_file),
            'oldest_entry_age': oldest_age,
            'newest_entry_age': newest_age
        }
    
    def __del__(self):
        """Destructor: save cache when the object is destroyed."""
        self._save_to_disk()
    
    def __len__(self) -> int:
        """Return the number of active (non-expired) entries in the cache."""
        self._cleanup_expired()
        return len(self._cache)
    
    def __contains__(self, key_string: str) -> bool:
        """Check if a key exists in the cache using 'in' operator."""
        return self.exists(key_string)
    
    def __repr__(self) -> str:
        """String representation of the cache."""
        stats = self.get_stats()
        return f"Cache(entries={stats['active_entries']}, ttl={stats['ttl_seconds']}s, max={stats['max_entries']})"


# Example usage
if __name__ == "__main__":
    # Create a cache (configuration will be loaded from cache_config.yaml)
    cache = Cache()
    
    # Store some values
    cache.set("user:123", {"name": "John", "age": 30})
    cache.set("user:456", {"name": "Jane", "age": 25})
    cache.set("config", {"theme": "dark", "language": "en"})
    
    # Retrieve values
    user = cache.get("user:123")
    print(f"Retrieved user: {user}")
    
    # Check if key exists
    if "config" in cache:
        print("Config exists in cache")
    
    # Get cache statistics
    stats = cache.get_stats()
    print(f"Cache stats:")
    for key, value in stats.items():
        print(f"  {key}: {value}")
    
    # Reload configuration (useful if config file was modified)
    # cache.reload_config()
    
    # Manual save
    cache.save()
    
    print(f"\nCache representation: {cache}")
    
    # The cache will be automatically saved when:
    # 1. The program exits normally
    # 2. CTRL+C is pressed
    # 3. The cache object is destroyed
