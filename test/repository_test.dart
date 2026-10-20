import 'package:flutter_test/flutter_test.dart';
import 'package:st_authenticator/data/app_repository.dart';
import 'package:st_authenticator/models/auth_app.dart';

import 'fakes.dart';

AuthApp app(String id, String name) => AuthApp(
      id: id,
      name: name,
      secretBase32: 'GEZDGNBVGY3TQOJQ',
      colorValue: 0xFF1E88E5,
      createdAt: DateTime.utc(2026, 1, 1),
    );

void main() {
  late FakeStore store;
  late StoredAppRepository repo;

  setUp(() async {
    store = FakeStore();
    repo = StoredAppRepository(store);
    await repo.load();
  });

  test('starts empty', () async {
    expect(await repo.load(), isEmpty);
  });

  test('add persists and survives a reload', () async {
    await repo.add(app('1', 'Alpha'));
    final again = await StoredAppRepository(store).load();
    expect(again.single.name, 'Alpha');
    expect(again.single.secretBase32, 'GEZDGNBVGY3TQOJQ');
    expect(again.single.digits, 6);
    expect(again.single.periodSeconds, 30);
  });

  test('duplicate names rejected (trim + case-insensitive)', () async {
    await repo.add(app('1', 'Alpha'));
    expect(() => repo.add(app('2', ' alpha ')),
        throwsA(isA<DuplicateNameException>()));
    await repo.add(app('2', 'Beta'));
    expect(() => repo.update(app('2', 'ALPHA')),
        throwsA(isA<DuplicateNameException>()));
    expect((await repo.load()).length, 2);
  });

  test('update keeps own name, changes fields', () async {
    await repo.add(app('1', 'Alpha'));
    await repo.update(app('1', 'Alpha').copyWith(digits: 8, name: 'Alpha'));
    expect((await repo.load()).single.digits, 8);
  });

  test('delete', () async {
    await repo.add(app('1', 'Alpha'));
    await repo.add(app('2', 'Beta'));
    await repo.delete('1');
    expect((await repo.load()).map((a) => a.id), ['2']);
  });

  test('reorder uses final index', () async {
    for (final n in ['A', 'B', 'C']) {
      await repo.add(app(n, n));
    }
    await repo.reorder(0, 2);
    expect((await repo.load()).map((a) => a.id), ['B', 'C', 'A']);
  });

  test('corrupt data throws instead of being overwritten', () async {
    store.data[StoredAppRepository.storageKey] = '{not json';
    expect(() => StoredAppRepository(store).load(),
        throwsA(isA<StorageException>()));
    expect(store.data[StoredAppRepository.storageKey], '{not json');
  });
}
