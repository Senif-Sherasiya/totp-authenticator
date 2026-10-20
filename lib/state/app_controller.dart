import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/app_repository.dart';
import '../models/auth_app.dart';

class AppController extends ChangeNotifier {
  AppController(this._repo);

  final AppRepository _repo;
  List<AuthApp> _apps = [];
  bool _loading = true;
  String? _error;

  List<AuthApp> get apps => List.unmodifiable(_apps);
  bool get loading => _loading;
  String? get error => _error;

  AuthApp? byId(String id) {
    for (final a in _apps) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _apps = await _repo.load();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  bool isNameTaken(String name, {String? exceptId}) {
    final k = name.trim().toLowerCase();
    return _apps.any((a) => a.id != exceptId && a.name.trim().toLowerCase() == k);
  }

  /// [secretBase32] must already be normalised.
  Future<AuthApp> add({
    required String name,
    required String secretBase32,
    required int digits,
    required int periodSeconds,
    required int colorValue,
  }) async {
    final app = AuthApp(
      id: const Uuid().v4(),
      name: name.trim(),
      secretBase32: secretBase32,
      digits: digits,
      periodSeconds: periodSeconds,
      colorValue: colorValue,
      createdAt: DateTime.now().toUtc(),
    );
    await _repo.add(app);
    _apps = [..._apps, app];
    notifyListeners();
    return app;
  }

  Future<void> update(AuthApp app) async {
    await _repo.update(app);
    _apps = [for (final a in _apps) a.id == app.id ? app : a];
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _apps = _apps.where((a) => a.id != id).toList();
    notifyListeners();
  }

  /// Updates the list immediately (so the drag drop doesn't snap back), then
  /// persists; reloads from storage if persisting fails.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final next = List.of(_apps);
    moveItem(next, oldIndex, newIndex);
    _apps = next;
    notifyListeners();
    try {
      await _repo.reorder(oldIndex, newIndex);
    } catch (_) {
      await load();
    }
  }
}
