import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/local_memory_service.dart';
import '../state/providers.dart';

class LocalMemoryScreen extends ConsumerWidget {
  const LocalMemoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountSessionProvider);
    return Scaffold(appBar: AppBar(title: const Text('Local coach memory')),
      body: !account.recoverable ? const Padding(padding: EdgeInsets.all(20), child: Text(
        'Local memory requires a signed-in recoverable account to keep account notes separate. '
        'No memory is assigned to a shared guest identity. Basic tracking is still available.'))
        : _MemoryBody(key: ValueKey(account.revision)));
  }
}
class _MemoryBody extends ConsumerStatefulWidget {
  const _MemoryBody({super.key});
  @override ConsumerState<_MemoryBody> createState() => _MemoryBodyState();
}
class _MemoryBodyState extends ConsumerState<_MemoryBody> {
  MemoryView? view;
  bool busy = true, exporting = false, confirmAll = false;
  int? editing, deleting;
  String kind = 'preference';
  String? failure;
  final text = TextEditingController();
  @override void initState() { super.initState(); load(); }
  @override void dispose() { text.dispose(); super.dispose(); }
  Future<void> load() async {
    setState(() { busy = true; failure = null; });
    try {
      final value = await ref.read(localMemoryServiceProvider).read();
      if (mounted) setState(() { view = value; });
    } catch (_) { if (mounted) setState(() { view = null; failure = 'Memory could not be loaded. Nothing was imported or sent.'; }); }
    finally { if (mounted) setState(() { busy = false; }); }
  }
  Future<void> change(Future<void> Function(LocalMemoryService, MemoryLease) action) async {
    if (busy || view == null) return;
    setState(() { busy = true; failure = null; exporting = false; });
    try {
      await action(ref.read(localMemoryServiceProvider), view!.lease);
      if (!mounted) return;
      text.clear(); editing = null; deleting = null; confirmAll = false;
      await load();
    } catch (_) {
      if (mounted) setState(() { failure = 'Change was not saved. Keep your text, then reload if the account or memory changed.'; busy = false; });
    }
  }
  String label(String value) => switch (value) {
    'preference' => 'User-confirmed preference',
    'user_statement' => 'User-stated information (not independently verified)',
    _ => 'Inference — not user-confirmed',
  };
  @override
  Widget build(BuildContext context) {
    final current = view;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Local draft memory only. These entries are not sent to AI, included in analytics, or used by the coach. '
        'Existing chats, photos, measurements and activity are not automatically imported.'),
      const Text('Turning off clears derived inferences and stops new memory edits. Your own entries remain inspectable and deletable. '
        'No automatic expiry is implemented. Delete controls below remove local memory only, not server data or ordinary tracking records.'),
      if (busy) const LinearProgressIndicator(),
      if (failure != null) ...[Text(failure!), TextButton(onPressed: busy ? null : load, child: const Text('Reload memory'))],
      if (current != null) ...[
        SwitchListTile(title: const Text('Keep optional local memory'), subtitle: const Text('Off by default. This is not consent to remote processing.'),
          value: current.enabled, onChanged: busy ? null : (value) => change((service, lease) => service.setEnabled(lease, value))),
        TextButton(onPressed: () => Navigator.pushNamed(context, '/trends'), child: const Text('View recorded activity separately')),
        if (current.entries.isEmpty) const Text('No local memory entries.'),
        for (final entry in current.entries) Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label(entry.kind), style: Theme.of(context).textTheme.titleSmall),
          Text(entry.text),
          Text('Source: ${entry.source}'),
          Text('Entered ${DateFormat.yMd().add_Hm().format(entry.createdAt.toLocal())}; updated ${DateFormat.yMd().add_Hm().format(entry.updatedAt.toLocal())}'),
          if (entry.sourceIds.isNotEmpty) Text('Derived from local entry IDs: ${entry.sourceIds.join(', ')}'),
          if (entry.kind != 'inference') TextButton(onPressed: busy || !current.enabled ? null : () => setState(() {
            editing = entry.id; kind = entry.kind; text.text = entry.text; exporting = false;
          }), child: const Text('Correct entry')),
          TextButton(onPressed: busy ? null : () => setState(() { deleting = entry.id; }), child: const Text('Delete entry')),
          if (deleting == entry.id) ...[const Text('Delete this entry and all derived inferences for this account?'),
            TextButton(onPressed: busy ? null : () => change((service, lease) => service.deleteEntry(lease, entry.id)), child: const Text('Confirm delete'))],
        ]))),
        if (current.enabled) ...[
          Text(editing == null ? 'Add information you choose to keep' : 'Correct selected entry'),
          DropdownButtonFormField<String>(key: ValueKey('$editing:$kind'), initialValue: kind,
            items: const [DropdownMenuItem(value: 'preference', child: Text('Preference')), DropdownMenuItem(value: 'user_statement', child: Text('User-stated information'))],
            onChanged: busy ? null : (value) => setState(() { kind = value!; })),
          TextField(controller: text, enabled: !busy, maxLength: 1000, maxLines: 3, decoration: const InputDecoration(labelText: 'Memory text')),
          const Text('The date records when you entered this note, not when an underlying event happened. No diagnosis is inferred.'),
          FilledButton(onPressed: busy ? null : () => change((service, lease) => service.saveEntry(lease, id: editing, kind: kind, text: text.text)), child: const Text('Save local entry')),
          if (editing != null) TextButton(onPressed: busy ? null : () => setState(() { editing = null; text.clear(); }), child: const Text('Cancel correction')),
        ],
        TextButton(onPressed: busy ? null : () => setState(() { exporting = !exporting; }), child: const Text('Inspect JSON export')),
        if (exporting) SelectableText(current.exportJson),
        TextButton(onPressed: busy ? null : () => setState(() { confirmAll = true; }), child: const Text('Delete all local memory')),
        if (confirmAll) ...[const Text('Remove local memory for this account and turn it off? Ordinary activity records will stay.'),
          TextButton(onPressed: busy ? null : () => change((service, lease) => service.deleteAll(lease)), child: const Text('Confirm delete all'))],
      ],
    ]);
  }
}
