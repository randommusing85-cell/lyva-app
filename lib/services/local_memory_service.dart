import 'dart:convert';
import 'package:isar/isar.dart';
import '../db/isar_db.dart';
import '../models/local_memory.dart';
import 'account_access_service.dart';

class MemoryLease {
  final String owner;
  final int accountRevision, revision;
  const MemoryLease(this.owner, this.accountRevision, this.revision);
}
class MemoryView {
  final MemoryLease lease;
  final bool enabled;
  final List<MemoryEntry> entries;
  const MemoryView(this.lease, this.enabled, this.entries);
  String get exportJson => jsonEncode({'version': 1, 'scope': 'local optional memory only', 'enabled': enabled,
    'entries': entries.map((e) => {'id': e.id, 'kind': e.kind, 'text': e.text, 'source': e.source,
      'createdAt': e.createdAt.toUtc().toIso8601String(), 'updatedAt': e.updatedAt.toUtc().toIso8601String(), 'sourceIds': e.sourceIds}).toList()});
}

/// Local draft memory only. No AI, network, analytics or ordinary health-record access.
/// Owner comes exclusively from the existing auth bridge, never a screen argument.
class LocalMemoryService {
  final AccountSession account;
  final Future<Isar> Function() open;
  final Future<void> Function()? beforeWrite;
  LocalMemoryService(this.account, {Future<Isar> Function()? openDatabase, this.beforeWrite}) : open = openDatabase ?? IsarDb.instance;
  MemoryLease _identity() {
    if (!account.recoverable || account.uid == null) throw StateError('A recoverable account is required for isolated memory.');
    return MemoryLease(account.uid!, account.revision, 0);
  }
  void _check(MemoryLease lease) {
    if (!account.recoverable || account.uid != lease.owner || account.revision != lease.accountRevision) {
      throw StateError('Account changed. Reload memory.');
    }
  }
  Future<MemoryView> read() async {
    final identity = _identity(), db = await open(); _check(identity);
    final space = await db.memorySpaces.filter().ownerEqualTo(identity.owner).findFirst();
    final entries = await db.memoryEntrys.filter().ownerEqualTo(identity.owner).sortByUpdatedAtDesc().findAll();
    _check(identity);
    return MemoryView(MemoryLease(identity.owner, identity.accountRevision, space?.revision ?? 0),
      space?.enabled ?? false, List.unmodifiable(entries));
  }
  Future<void> _mutate(MemoryLease lease, Future<void> Function(Isar, MemorySpace) change) async {
    _check(lease); final db = await open(); _check(lease);
    await db.writeTxn(() async {
      final space = await db.memorySpaces.filter().ownerEqualTo(lease.owner).findFirst() ?? (MemorySpace()..owner = lease.owner);
      if (space.revision != lease.revision) throw StateError('Memory changed. Reload before editing.');
      if (beforeWrite != null) await beforeWrite!();
      _check(lease);
      await change(db, space);
      space.revision++;
      await db.memorySpaces.put(space);
      _check(lease); // Throwing here rolls the transaction back.
    });
    _check(lease);
  }
  Future<void> _clearDerived(Isar db, String owner) => db.memoryEntrys.filter().ownerEqualTo(owner).and().kindEqualTo('inference').deleteAll().then((_) {});
  String _text(String text) {
    final value = text.trim();
    if (value.isEmpty || value.length > 1000) throw const FormatException('Use 1 to 1000 characters.');
    return value;
  }
  Future<void> setEnabled(MemoryLease lease, bool value) => _mutate(lease, (db, space) async {
    space.enabled = value; await _clearDerived(db, lease.owner);
  });
  Future<void> saveEntry(MemoryLease lease, {int? id, required String kind, required String text}) async {
    if (!['user_statement', 'preference'].contains(kind)) throw ArgumentError('Only explicit user entries can be saved here.');
    final value = _text(text);
    await _mutate(lease, (db, space) async {
      if (!space.enabled) throw StateError('Optional local memory is off.');
      MemoryEntry entry;
      if (id == null) { entry = MemoryEntry()..owner = lease.owner..createdAt = DateTime.now(); }
      else {
        final existing = await db.memoryEntrys.get(id);
        if (existing == null || existing.owner != lease.owner || existing.kind == 'inference') throw StateError('Entry unavailable.');
        entry = existing;
      }
      entry.kind = kind; entry.text = value; entry.updatedAt = DateTime.now();
      entry.source = id == null ? 'User entered' : 'User corrected';
      entry.sourceIds = [];
      await db.memoryEntrys.put(entry); await _clearDerived(db, lease.owner);
    });
  }
  Future<void> deleteEntry(MemoryLease lease, int id) => _mutate(lease, (db, space) async {
    final entry = await db.memoryEntrys.get(id);
    if (entry == null || entry.owner != lease.owner) throw StateError('Entry unavailable.');
    await db.memoryEntrys.delete(id); await _clearDerived(db, lease.owner);
  });
  Future<void> deleteAll(MemoryLease lease) => _mutate(lease, (db, space) async {
    await db.memoryEntrys.filter().ownerEqualTo(lease.owner).deleteAll();
    space.enabled = false; // Keep revision tombstone; never reset the stale-write barrier.
  });
  /// Testable seam only; no app producer currently generates these inferences.
  Future<void> completeInference(MemoryLease lease, List<int> sourceIds, String text) async {
    final value = _text(text);
    if (sourceIds.isEmpty || sourceIds.length > 20) throw ArgumentError('Explicit sources required.');
    await _mutate(lease, (db, space) async {
      if (!space.enabled) throw StateError('Optional local memory is off.');
      for (final id in sourceIds.toSet()) {
        final source = await db.memoryEntrys.get(id);
        if (source == null || source.owner != lease.owner || source.kind == 'inference') throw StateError('Source unavailable.');
      }
      await db.memoryEntrys.put(MemoryEntry()..owner = lease.owner..kind = 'inference'..text = value
        ..source = 'Local derivation; not user-confirmed'..createdAt = DateTime.now()..updatedAt = DateTime.now()..sourceIds = sourceIds.toSet().toList());
    });
  }
}
