import 'dart:async';
import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

/// Local source of truth. Every repository reads from here first, so the app
/// remains fully usable without a network connection.
class LocalStore {
  static const List<String> dataTables = [
    'categories',
    'wallets',
    'wallet_members',
    'transactions',
    'budgets',
    'recurring_rules',
    'case_notes',
    'receipts',
    'reports',
  ];

  final Map<String, Box<String>> _boxes = {};
  late Box<dynamic> _meta;
  late Box<String> _outbox;
  late Box<String> _images;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init({String? directory, String name = 'dompetektif'}) async {
    if (_initialized) return;
    if (directory == null) {
      await Hive.initFlutter(name);
    } else {
      Hive.init(directory);
    }

    _meta = await Hive.openBox<dynamic>('meta');
    for (final table in dataTables) {
      _boxes[table] = await Hive.openBox<String>(table);
    }
    _outbox = await Hive.openBox<String>('outbox');
    _images = await Hive.openBox<String>('receipt_images');
    _initialized = true;
  }

  Future<void> close() async {
    await Hive.close();
    _initialized = false;
  }

  Box<String> _box(String table) {
    final box = _boxes[table];
    if (box == null) {
      throw StateError('Unknown local table: $table');
    }
    return box;
  }

  Map<String, dynamic>? get(String table, String id) {
    final raw = _box(table).get(id);
    if (raw == null) return null;
    return _decode(raw);
  }

  List<Map<String, dynamic>> all(String table) {
    final result = <Map<String, dynamic>>[];
    for (final raw in _box(table).values) {
      final decoded = _decode(raw);
      if (decoded != null) result.add(decoded);
    }
    return result;
  }

  Stream<List<Map<String, dynamic>>> watch(String table) {
    final box = _box(table);

    List<Map<String, dynamic>> read() {
      final result = <Map<String, dynamic>>[];
      for (final raw in box.values) {
        final decoded = _decode(raw);
        if (decoded != null) result.add(decoded);
      }
      return result;
    }

    return Stream.multi((controller) {
      controller.add(read());
      final subscription = box.watch().listen((_) => controller.add(read()));
      controller.onCancel = subscription.cancel;
    });
  }

  Future<void> put(
    String table,
    Map<String, dynamic> row, {
    bool pending = false,
  }) async {
    final payload = Map<String, dynamic>.from(row);
    if (pending) {
      payload['is_pending'] = true;
    } else {
      payload.remove('is_pending');
    }
    await _box(table).put(row['id'] as String, jsonEncode(payload));
  }

  Future<void> putMany(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final box = _box(table);
    final entries = <String, String>{
      for (final row in rows) row['id'] as String: jsonEncode(row),
    };
    await box.putAll(entries);
  }

  Future<void> delete(String table, String id) => _box(table).delete(id);

  Future<void> clearTable(String table) => _box(table).clear();

  Future<void> clearAllData() async {
    for (final table in dataTables) {
      await _box(table).clear();
    }
    await _outbox.clear();
    await _images.clear();
    await _meta.clear();
  }

  /// Removes case data when a session ends while keeping device preferences.
  ///
  /// The local store is shared by every session on this device. Clearing the
  /// synced tables on sign-out prevents the next investigator from seeing a
  /// previous account's wallets, receipts, or pending changes.
  Future<void> clearUserData() async {
    for (final table in dataTables) {
      await _box(table).clear();
    }
    await _outbox.clear();
    await _images.clear();

    final keys = _meta.keys.map((key) => key.toString()).toList();
    for (final key in keys) {
      if (key.startsWith('sync_cursor_') ||
          key.startsWith('alert_sent_') ||
          key == 'seed_version' ||
          key == 'demo_user') {
        await _meta.delete(key);
      }
    }

    final settings = _meta.get('settings');
    if (settings is Map) {
      final sanitized = Map<String, dynamic>.from(settings)
        ..remove('active_wallet_id');
      await _meta.put('settings', sanitized);
    }
  }

  Future<void> markSynced(String table, String id) async {
    final row = get(table, id);
    if (row == null) return;
    row.remove('is_pending');
    await put(table, row);
  }

  dynamic getMeta(String key) => _meta.get(key);

  Future<void> setMeta(String key, dynamic value) => _meta.put(key, value);

  Future<void> removeMeta(String key) => _meta.delete(key);

  Stream<void> watchMeta(String key) => _meta.watch(key: key).map((_) {});

  Future<void> enqueueOutbox(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    await _outbox.put(id, jsonEncode(item));
  }

  List<Map<String, dynamic>> outboxItems() {
    final items = <Map<String, dynamic>>[];
    for (final raw in _outbox.values) {
      final decoded = _decode(raw);
      if (decoded != null) items.add(decoded);
    }
    items.sort(
      (a, b) => (a['created_at'] as String? ?? '').compareTo(
        b['created_at'] as String? ?? '',
      ),
    );
    return items;
  }

  Future<void> removeOutbox(String id) => _outbox.delete(id);

  Future<void> clearOutbox() => _outbox.clear();

  Stream<int> watchOutboxCount() {
    return Stream.multi((controller) {
      controller.add(_outbox.length);
      final subscription = _outbox.watch().listen(
        (_) => controller.add(_outbox.length),
      );
      controller.onCancel = subscription.cancel;
    });
  }

  Future<void> saveImage(String key, List<int> bytes) =>
      _images.put(key, base64Encode(bytes));

  List<int>? loadImage(String key) {
    final value = _images.get(key);
    if (value == null) return null;
    try {
      return base64Decode(value);
    } on FormatException {
      return null;
    }
  }

  Future<void> deleteImage(String key) => _images.delete(key);

  Map<String, dynamic>? _decode(String raw) {
    try {
      final value = jsonDecode(raw);
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    } on FormatException {
      return null;
    }
  }
}
