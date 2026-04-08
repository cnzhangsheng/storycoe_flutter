import 'dart:collection';

/// LRU (Least Recently Used) Cache implementation
/// Automatically evicts the least recently used item when the cache is full
class LruCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap();

  LruCache({this.maxSize = 10});

  /// Get an item from the cache
  /// Returns null if the key doesn't exist
  /// Moves the item to the end (most recently used)
  V? get(K key) {
    if (!_cache.containsKey(key)) return null;

    // Remove and re-add to move to end (most recently used)
    final value = _cache.remove(key);
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  /// Put an item into the cache
  /// If the cache is full, removes the least recently used item
  void put(K key, V value) {
    // If key exists, remove it first (will be re-added at end)
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }
    // If cache is full, remove the least recently used (first item)
    else if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }
    // Add to end (most recently used)
    _cache[key] = value;
  }

  /// Check if a key exists in the cache
  bool containsKey(K key) => _cache.containsKey(key);

  /// Get the number of items in the cache
  int get length => _cache.length;

  /// Check if the cache is empty
  bool get isEmpty => _cache.isEmpty;

  /// Check if the cache is not empty
  bool get isNotEmpty => _cache.isNotEmpty;

  /// Get all keys in the cache (in LRU order)
  Iterable<K> get keys => _cache.keys;

  /// Get all values in the cache (in LRU order)
  Iterable<V> get values => _cache.values;

  /// Remove a specific key from the cache
  V? remove(K key) => _cache.remove(key);

  /// Clear all items from the cache
  void clear() => _cache.clear();

  /// Convert to a regular Map
  Map<K, V> toMap() => Map.from(_cache);

  /// Create a copy of this cache
  LruCache<K, V> copy() {
    final newCache = LruCache<K, V>(maxSize: maxSize);
    newCache._cache.addAll(_cache);
    return newCache;
  }

  @override
  String toString() => 'LruCache(maxSize: $maxSize, items: ${_cache.length})';
}