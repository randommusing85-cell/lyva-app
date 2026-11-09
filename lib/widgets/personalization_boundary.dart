import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';

class PersonalizationBoundary extends ConsumerWidget {
  final Widget child;
  const PersonalizationBoundary({super.key, required this.child});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(personalizationDecisionProvider);
    final decision = state.asData?.value;
    if (decision?.allowed == true) return child;
    return Scaffold(appBar: AppBar(title: const Text('Personalized guidance')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        Text(decision?.message ?? 'Checking your profile. Personalized guidance is unavailable until this check succeeds.'),
        const SizedBox(height: 16),
        const Text('Your saved records are preserved. Tracking remains available from Home.'),
        TextButton(onPressed: () => Navigator.pushNamed(context, '/edit-profile'), child: const Text('Review profile')),
      ])));
  }
}

/// Each detached route owns its gate. A revoked preview never reappears if
/// eligibility later returns; closing never dismisses an unrelated route.
class PersonalizationModalBoundary extends ConsumerStatefulWidget {
  final WidgetBuilder builder;
  final VoidCallback? onClose;
  const PersonalizationModalBoundary({super.key, required this.builder, this.onClose});
  @override
  ConsumerState<PersonalizationModalBoundary> createState() => _PersonalizationModalState();
}
class _PersonalizationModalState extends ConsumerState<PersonalizationModalBoundary> {
  bool revoked = false;
  @override
  Widget build(BuildContext context) {
    ref.listen(personalizationDecisionProvider, (_, next) {
      if (next.asData?.value.allowed != true && !revoked) {
        setState(() => revoked = true);
      }
    });
    final decision = ref.watch(personalizationDecisionProvider).asData?.value;
    if (decision?.allowed != true) revoked = true;
    if (!revoked) return Builder(builder: widget.builder);
    return AlertDialog(
      title: const Text('Personalized guidance unavailable'),
      content: const Text('This preview is no longer available. No acceptance is recorded by closing it. Your saved records are preserved.'),
      actions: [TextButton(onPressed: () {
        if (widget.onClose != null) { widget.onClose!();return; }
        if (ModalRoute.of(context)?.isCurrent == true) Navigator.of(context).pop();
      }, child: const Text('Close preview'))],
    );
  }
}

Future<T?> showPersonalizationDialog<T>({required BuildContext context,
  required WidgetBuilder builder, bool barrierDismissible = true}) {
  final container = ProviderScope.containerOf(context, listen: false);
  return showDialog<T>(context: context, barrierDismissible: barrierDismissible,
    builder: (ctx) => UncontrolledProviderScope(container: container,
      child: PersonalizationModalBoundary(builder: builder)));
}

Future<T?> showPersonalizationBottomSheet<T>({required BuildContext context,
  required WidgetBuilder builder, bool isScrollControlled = false,
  ShapeBorder? shape}) {
  final container = ProviderScope.containerOf(context, listen: false);
  return showModalBottomSheet<T>(context: context, isScrollControlled: isScrollControlled, shape: shape,
    builder: (ctx) => UncontrolledProviderScope(container: container,
      child: PersonalizationModalBoundary(builder: builder)));
}
