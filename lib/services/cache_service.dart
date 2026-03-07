import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A lightweight TTL-based cache backed by SharedPreferences.
///
/// Each entry stores two keys:
///   cache_data_<key>  →  JSON-encoded value
///   cache_ts_<key>    →  Unix timestamp (ms) of when it was written
///
/// Usage:
///   final cache = CacheService();
///   await cache.init();
///
///   // Write
///   await cache.set('profile', myMap, ttl: Duration(hours: 1));
///
///   // Read (returns null if missing or expired)
///   final data = await cache.get('profile');
///
///   // Invalidate
///   await cache.invalidate('profile');
class CacheService {
  static const String _dataPrefix = 'cache_data_';
  static const String _tsPrefix   = 'cache_ts_';

  // Singleton so all callers share one SharedPreferences instance
  static CacheService? _instance;
  factory CacheService() => _instance ??= CacheService._();
  CacheService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'CacheService.init() must be called before use');
    return _prefs!;
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<void> set(String key, dynamic value, {required Duration ttl}) async {
    await _p.setString(_dataPrefix + key, jsonEncode(value));
    await _p.setInt(_tsPrefix + key, DateTime.now().millisecondsSinceEpoch);
    // Store TTL so isExpired can check it
    await _p.setInt('cache_ttl_$key', ttl.inMilliseconds);
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Returns the cached value if it exists AND is within TTL.
  /// Returns null if missing or stale.
  Future<dynamic> get(String key) async {
    final ts  = _p.getInt(_tsPrefix + key);
    final ttl = _p.getInt('cache_ttl_$key');
    final raw = _p.getString(_dataPrefix + key);

    if (ts == null || ttl == null || raw == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > ttl) {
      // Stale — clean up silently
      await invalidate(key);
      return null;
    }

    return jsonDecode(raw);
  }

  /// Returns cached value even if stale (for stale-while-revalidate pattern).
  Future<dynamic> getStale(String key) async {
    final raw = _p.getString(_dataPrefix + key);
    return raw != null ? jsonDecode(raw) : null;
  }

  Future<bool> isExpired(String key) async {
    final ts  = _p.getInt(_tsPrefix + key);
    final ttl = _p.getInt('cache_ttl_$key');
    if (ts == null || ttl == null) return true;
    return (DateTime.now().millisecondsSinceEpoch - ts) > ttl;
  }

  // ── Invalidate ────────────────────────────────────────────────────────────

  Future<void> invalidate(String key) async {
    await _p.remove(_dataPrefix + key);
    await _p.remove(_tsPrefix   + key);
    await _p.remove('cache_ttl_$key');
  }

  Future<void> invalidateAll() async {
    final keys = _p.getKeys()
        .where((k) => k.startsWith(_dataPrefix) ||
                      k.startsWith(_tsPrefix)   ||
                      k.startsWith('cache_ttl_'))
        .toList();
    for (final k in keys) {
      await _p.remove(k);
    }
  }

  // ── Named TTL constants used across the app ───────────────────────────────

  static const Duration profileTTL     = Duration(hours: 1);
  static const Duration bearerTokenTTL = Duration(minutes: 55);  // JWT expires in 60min
  static const Duration qrDataTTL      = Duration(minutes: 10);
  static const Duration menusTTL       = Duration(hours: 6);
}
