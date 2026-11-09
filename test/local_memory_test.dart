import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:lyva_app/models/checkin.dart';
import 'package:lyva_app/models/local_memory.dart';
import 'package:lyva_app/services/account_access_service.dart';
import 'package:lyva_app/services/local_memory_service.dart';
import 'package:lyva_app/screens/local_memory_screen.dart';
import 'package:lyva_app/state/providers.dart';

class MemoryUiService extends LocalMemoryService {
  MemoryView snapshot;
  MemoryUiService(super.account, this.snapshot);
  @override Future<void> setEnabled(MemoryLease lease, bool value) async { snapshot = MemoryView(lease, value, snapshot.entries); }
  @override Future<void> saveEntry(MemoryLease lease, {int? id, required String kind, required String text}) async {
    snapshot = MemoryView(lease, true, [MemoryEntry()..id = id ?? 1..owner = lease.owner..kind = kind..text = text..source = 'User entered'..createdAt = DateTime(2026)..updatedAt = DateTime(2026)]);
  }
  @override Future<void> deleteEntry(MemoryLease lease, int id) async { snapshot = MemoryView(lease, snapshot.enabled, []); }
  @override Future<MemoryView> read() async => account.uid == snapshot.lease.owner
    ? MemoryView(MemoryLease(account.uid!, account.revision, snapshot.lease.revision), snapshot.enabled, snapshot.entries)
    : MemoryView(MemoryLease(account.uid!, account.revision, 0), false, []);
}
void main() {
  late Directory directory; late Isar db; late AccountSession account; late LocalMemoryService service;
  Future<Isar> open() => Isar.open([MemorySpaceSchema, MemoryEntrySchema, CheckInSchema], directory: directory.path, name: 'memory', inspector: false);
  setUpAll(() async { await Isar.initializeIsarCore(libraries: {
    Abi.windowsX64: File('vendor/isar_flutter_libs/windows/isar.dll').absolute.path,
    Abi.linuxX64: File('vendor/isar_flutter_libs/linux/libisar.so').absolute.path,
    Abi.macosX64: File('vendor/isar_flutter_libs/macos/libisar.dylib').absolute.path,
    Abi.macosArm64: File('vendor/isar_flutter_libs/macos/libisar.dylib').absolute.path,
  }); });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('lyva_local_memory_'); db = await open();
    account = AccountSession()..updateFromAuthBridge(uid: 'fixture-a', recoverable: true);
    service = LocalMemoryService(account, openDatabase: () async => db);
  });
  tearDown(() async { if (db.isOpen) await db.close(deleteFromDisk: true); await directory.delete(recursive: true); });
  Future<MemoryView> seed() async {
    await service.setEnabled((await service.read()).lease, true);
    await service.saveEntry((await service.read()).lease, kind: 'preference', text: 'Prefer morning sessions');
    return service.read();
  }
  test('off by default, no existing record import, and explicit enable required', () async {
    final view = await service.read(); expect(view.enabled, isFalse); expect(view.entries, isEmpty);
    await expectLater(service.saveEntry(view.lease, kind: 'preference', text: 'test'), throwsStateError);
    expect(await db.memoryEntrys.count(), 0);
  });
  test('correction removes derived notes and invalidates delayed responses and stale edits', () async {
    final first = await seed(), id = (await service.read()).entries.single.id;
    await service.completeInference(first.lease, [id], 'Fixture inference');
    final withInference = await service.read(); expect(withInference.entries.length, 2);
    await service.saveEntry(withInference.lease, id: id, kind: 'preference', text: 'Prefer evenings');
    final corrected = await service.read(); expect(corrected.entries.single.text, 'Prefer evenings');
    expect(corrected.entries.single.source, 'User corrected');
    await expectLater(service.completeInference(first.lease, [id], 'Old response'), throwsStateError);
    await expectLater(service.saveEntry(first.lease, id: id, kind: 'preference', text: 'stale'), throwsStateError);
  });
  test('delete-all survives reopen and re-enable without stale resurrection or health deletion', () async {
    final health = CheckIn()..ts = DateTime(2026)..moodScore = 3;
    await db.writeTxn(() async { await db.checkIns.put(health); });
    final first = await seed();
    await service.deleteAll(first.lease);
    await db.close(); db = await open();
    final cleared = await service.read(); expect(cleared.enabled, isFalse); expect(cleared.entries, isEmpty);
    await service.setEnabled(cleared.lease, true);
    await expectLater(service.completeInference(first.lease, [first.entries.single.id], 'Delayed'), throwsStateError);
    await expectLater(service.saveEntry(first.lease, kind: 'user_statement', text: 'Delayed add'), throwsStateError);
    expect((await db.checkIns.get(health.id))!.moodScore, 3);
  });
  test('disable clears inferences, preserves inspectable user entries, and prevents new writes', () async {
    final first = await seed(); await service.completeInference(first.lease, [first.entries.single.id], 'Unconfirmed');
    await service.setEnabled((await service.read()).lease, false);
    final off = await service.read(); expect(off.entries.single.kind, 'preference');
    await expectLater(service.saveEntry(off.lease, kind: 'preference', text: 'blocked'), throwsStateError);
    await service.deleteEntry(off.lease, off.entries.single.id); expect((await service.read()).entries, isEmpty);
  });
  test('account scopes, sign-out and switch-away/back reject old access', () async {
    final a = await seed();
    account.updateFromAuthBridge(uid: 'fixture-b', recoverable: true);
    expect((await service.read()).entries, isEmpty); expect((await service.read()).enabled, isFalse);
    await expectLater(service.deleteEntry((await service.read()).lease, a.entries.single.id), throwsStateError);
    await expectLater(service.saveEntry(a.lease, kind: 'preference', text: 'old account'), throwsStateError);
    account.updateFromAuthBridge(); await expectLater(service.read(), throwsStateError);
    account.updateFromAuthBridge(uid: 'fixture-a', recoverable: true);
    expect((await service.read()).entries.single.text, 'Prefer morning sessions');
    await expectLater(service.deleteAll(a.lease), throwsStateError);
  });
  test('account switch while write is pending rolls back transaction', () async {
    final view = await seed(); final entered = Completer<void>(), release = Completer<void>();
    final delayed = LocalMemoryService(account, openDatabase: () async => db, beforeWrite: () async { entered.complete(); await release.future; });
    final pending = delayed.saveEntry(view.lease, kind: 'user_statement', text: 'Must not appear');
    final assertion = expectLater(pending, throwsStateError);
    await entered.future; account.updateFromAuthBridge(uid: 'fixture-b', recoverable: true); release.complete(); await assertion;
    account.updateFromAuthBridge(uid: 'fixture-a', recoverable: true); expect((await service.read()).entries.length, 1);
  });
  test('unsupported types, invalid sources and empty text fail closed; export is local and labelled', () async {
    final view = await seed();
    await expectLater(service.saveEntry(view.lease, kind: 'inference', text: 'diagnosis'), throwsArgumentError);
    await expectLater(service.saveEntry(view.lease, kind: 'preference', text: ' '), throwsFormatException);
    await expectLater(service.completeInference(view.lease, [999], 'Unsupported'), throwsStateError);
    final data = jsonDecode(view.exportJson); expect(data['scope'], 'local optional memory only');
    expect(view.exportJson, isNot(contains('fixture-a'))); expect(data['entries'][0]['kind'], 'preference');
    expect(data['entries'][0]['createdAt'], isNotEmpty);
  });
  test('adding memory collections to existing database preserves ordinary records without importing them', () async {
    await db.close(deleteFromDisk: true);
    final old = await Isar.open([CheckInSchema], directory: directory.path, name: 'memory', inspector: false);
    final c = CheckIn()..ts = DateTime(2025)..weightKg = 70..note = 'Fixture health note';
    await old.writeTxn(() async { await old.checkIns.put(c); }); await old.close(); db = await open();
    expect((await db.checkIns.get(c.id))!.note, 'Fixture health note');
    expect((await service.read()).entries, isEmpty); expect((await service.read()).enabled, isFalse);
  });
  Future<void> render(WidgetTester tester, {LocalMemoryService? uiService}) async {
    tester.view.physicalSize = const Size(1000, 1800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(overrides: [accountSessionProvider.overrideWith((ref) => account), localMemoryServiceProvider.overrideWithValue(uiService ?? service)], child: const MaterialApp(home: LocalMemoryScreen())));
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 30)); }); await tester.pumpAndSettle();
  }
  testWidgets('guest view does not assign memory or require ordinary logging to stop', (tester) async {
    account.updateFromAuthBridge(); await render(tester);
    expect(find.textContaining('Basic tracking is still available'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
  });
  testWidgets('account switch clears displayed entries, export and unsaved draft', (tester) async {
    final snapshot = (await tester.runAsync(seed))!; await render(tester, uiService: MemoryUiService(account, snapshot));
    expect(find.text('Prefer morning sessions'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Unsaved fixture');
    await tester.tap(find.text('Inspect JSON export')); await tester.pumpAndSettle();
    account.updateFromAuthBridge(uid: 'fixture-b', recoverable: true);
    await tester.pump(); await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 30)); }); await tester.pumpAndSettle();
    expect(find.text('Prefer morning sessions'), findsNothing); expect(find.text('Unsaved fixture'), findsNothing);
    expect(find.byType(SelectableText), findsNothing); expect(find.text('No local memory entries.'), findsOneWidget);
  });
  test('concurrent first writes cannot create multiple owner state records', () async {
    final lease = (await service.read()).lease;
    final results = await Future.wait([service.setEnabled(lease, true).then((_) => true).catchError((_) => false),
      service.setEnabled(lease, true).then((_) => true).catchError((_) => false)]);
    expect(results.where((v) => v).length, 1);
    expect(await db.memorySpaces.count(), 1);
  });
  testWidgets('local controls enable, add, correct and confirm deletion', (tester) async {
    final initial = (await tester.runAsync(service.read))!;
    final ui = MemoryUiService(account, initial);
    await render(tester, uiService: ui);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byType(Switch)); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Fixture preference');
    await tester.tap(find.text('Save local entry')); await tester.pumpAndSettle();
    expect(find.text('Fixture preference'), findsOneWidget);
    await tester.tap(find.text('Correct entry')); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Corrected fixture');
    await tester.tap(find.text('Save local entry')); await tester.pumpAndSettle();
    expect(find.text('Corrected fixture'), findsOneWidget);
    await tester.tap(find.text('Delete entry')); await tester.pumpAndSettle();
    expect(ui.snapshot.entries, isNotEmpty);
    await tester.tap(find.text('Confirm delete')); await tester.pumpAndSettle();
    expect(ui.snapshot.entries, isEmpty);
  });

  test('delayed read cannot return an old account view after switching', () async {
    await seed(); final gate = Completer<Isar>();
    final delayed = LocalMemoryService(account, openDatabase: () => gate.future);
    final pending = expectLater(delayed.read(), throwsStateError);
    account.updateFromAuthBridge(uid: 'fixture-b', recoverable: true); gate.complete(db); await pending;
  });
  test('individual source deletion removes derived notes and rejects missing-source regeneration', () async {
    final first = await seed(); final id = first.entries.single.id;
    await service.completeInference(first.lease, [id], 'Derived fixture');
    await service.deleteEntry((await service.read()).lease, id);
    final deleted = await service.read(); expect(deleted.entries, isEmpty);
    await expectLater(service.completeInference(deleted.lease, [id], 'Regenerate deleted source'), throwsStateError);
    expect((await service.read()).entries, isEmpty);
  });

}
