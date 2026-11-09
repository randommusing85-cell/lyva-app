import '../services/personalization_safety.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'personalization_boundary.dart';
import 'dart:async';
import 'package:flutter/material.dart';

/// A full-screen overlay that shows while AI is generating plans.
/// Provides visual feedback with animated indicators and helpful tips.
class GeneratingOverlay extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<String> tips;

  const GeneratingOverlay({
    super.key,
    required this.title,
    this.subtitle,
    this.tips = const [
      'Analyzing your profile...',
      'Optimizing for your goals...',
      'Personalizing recommendations...',
      'Fine-tuning the details...',
    ],
  });

  @override
  State<GeneratingOverlay> createState() => _GeneratingOverlayState();
}

class _GeneratingOverlayState extends State<GeneratingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  int _currentTipIndex = 0;
  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Rotate tips every 2.5 seconds
    if (widget.tips.isNotEmpty) {
      _tipTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
        if (mounted) {
          setState(() {
            _currentTipIndex = (_currentTipIndex + 1) % widget.tips.length;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 48,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Title
                Text(
                  widget.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (widget.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 32),

                // Progress indicator
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                const SizedBox(height: 32),

                // Rotating tips
                if (widget.tips.isNotEmpty)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      widget.tips[_currentTipIndex],
                      key: ValueKey(_currentTipIndex),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 48),

                // Helpful message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'This usually takes 10-20 seconds',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a generating overlay as a modal route
Future<T?> showGeneratingOverlay<T>({
  required BuildContext context,
  required Future<T> Function() task,
  required String title,
  String? subtitle,
  List<String>? tips,
}) async {
  T? result;
  Object? error;

  // Show the overlay
  final container = ProviderScope.containerOf(context, listen: false);
  var removed = false;
  var cancelled = false;
  late OverlayEntry overlayEntry;
  void dismiss() {
    if (!removed) { removed = true;overlayEntry.remove(); }
  }
  overlayEntry = OverlayEntry(
    builder: (context) => UncontrolledProviderScope(container: container,
      child: PersonalizationModalBoundary(onClose: () { cancelled = true;dismiss(); }, builder: (context) => GeneratingOverlay(
      title: title,
      subtitle: subtitle,
      tips: tips ?? const [
        'Analyzing your profile...',
        'Optimizing for your goals...',
        'Personalizing recommendations...',
        'Fine-tuning the details...',
      ],
    ))),
  );

  Overlay.of(context).insert(overlayEntry);

  try {
    result = await task();
  } catch (e) {
    error = e;
  } finally {
    dismiss();
    overlayEntry.dispose();
  }

  if (cancelled) throw const PersonalizationUnavailable('This preview was closed. No result will be shown.');
  if (error != null) {
    throw error;
  }

  return result;
}
