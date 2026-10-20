import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_app.dart';

class DuplicateNameException implements Exception {
  const DuplicateNameException(this.name);
  final String name;
  @override
  String toString() => 'An app named "$name" already exists';
}

class StorageException implements Exception {
  const StorageException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Moves an item so it ends up at [newIndex] (the final position, as
/// reported by ReorderableListView.onReorderItem).
void moveItem<T>(List<T> list, int oldIndex, int newIndex) {
  list.insert(newIndex, list.removeAt(oldIndex));
}

abstract class AppRepository {
  Future<List<AuthApp>> load();
  Future<void> add(AuthApp app);
  Future<void> update(AuthApp app);
  Future<void> delete(String id);
  Future<void> reorder(int oldIndex, int newIndex);
}

/// Minimal string store so the repository can be tested without a platform.
abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class SecureKeyValueStore implements KeyValueStore {
  SecureKeyValueStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

/// Stores the whole list (secrets included) as one JSON string in the store.
class StoredAppRepository implements AppRepository {
  StoredAppRepository(this._store);

  static const storageKey = 'auth_apps_v1';
  final KeyValueStore _store;
  List<AuthApp>? _apps;

  @override
  Future<List<AuthApp>> load() async {
    final raw = await _store.read(storageKey);
    if (raw == null || raw.isEmpty) {
      _apps = [];
    } else {
      try {
        _apps = (jsonDecode(raw) as List)
            .map((e) => AuthApp.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Never overwrite unreadable data with an empty list.
        throw const StorageException('Stored data could not be read');
      }
    }
    return List.of(_apps!);
  }

  List<AuthApp> get _loaded {
    final apps = _apps;
    if (apps == null) throw StateError('load() must be called first');
    return apps;
  }

  Future<void> _commit(List<AuthApp> next) async {
    await _store.write(
        storageKey, jsonEncode(next.map((a) => a.toJson()).toList()));
    _apps = next;
  }

  static String _key(String name) => name.trim().toLowerCase();

  @override
  Future<void> add(AuthApp app) async {
    final list = List.of(_loaded);
    if (list.any((a) => _key(a.name) == _key(app.name))) {
      throw DuplicateNameException(app.name);
    }
    await _commit(list..add(app));
  }

  @override
  Future<void> update(AuthApp app) async {
    final list = List.of(_loaded);
    final i = list.indexWhere((a) => a.id == app.id);
    if (i < 0) throw StateError('Unknown app id ${app.id}');
    if (list.any((a) => a.id != app.id && _key(a.name) == _key(app.name))) {
      throw DuplicateNameException(app.name);
    }
    list[i] = app;
    await _commit(list);
  }

  @override
  Future<void> delete(String id) async {
    await _commit(List.of(_loaded)..removeWhere((a) => a.id == id));
  }

  @override
  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = List.of(_loaded);
    moveItem(list, oldIndex, newIndex);
    await _commit(list);
  }
}
