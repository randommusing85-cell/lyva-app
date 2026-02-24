import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coach_message.dart';
import '../models/ai_insight.dart';
import '../services/premium_service.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/coach_message_bubble.dart';
import '../widgets/ai_insight_card.dart';
import '../widgets/premium_gate.dart';

class AiCoachingScreen extends ConsumerStatefulWidget {
  const AiCoachingScreen({super.key});

  @override
  ConsumerState<AiCoachingScreen> createState() => _AiCoachingScreenState();
}

class _AiCoachingScreenState extends ConsumerState<AiCoachingScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  int _assistantMessageCount = 0;

  static const _suggestedPrompts = [
    "How's my progress?",
    "What should I eat today?",
    "Adjust my workout?",
    "Am I on track?",
  ];

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logAiCoachSessionStarted();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _sending) return;

    // Check usage cap before sending
    final profile = await ref.read(userProfileProvider.future);
    if (profile != null) {
      final service = ref.read(premiumServiceProvider);
      if (!service.canSendCoachMessage(profile)) {
        if (mounted) {
          _showUsageLimitDialog();
        }
        return;
      }
    }

    final message = text.trim();
    _inputCtrl.clear();
    setState(() => _sending = true);

    final repo = ref.read(primeRepoProvider);

    // Save user message
    final userMsg = CoachMessage()
      ..ts = DateTime.now()
      ..role = 'user'
      ..content = message;
    await repo.addCoachMessage(userMsg);

    // Save loading placeholder
    final loadingMsg = CoachMessage()
      ..ts = DateTime.now().add(const Duration(milliseconds: 1))
      ..role = 'assistant'
      ..content = ''
      ..isLoading = true;
    await repo.addCoachMessage(loadingMsg);

    try {
      // Build context
      final context = await repo.buildCoachingContext();

      // Get recent history
      final recent = await repo.getRecentCoachMessages(limit: 20);
      final history = recent
          .where((m) => !m.isLoading)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList()
          .reversed
          .toList();

      // Get AI insights for enhanced context
      final insights = await repo.getActiveInsights();
      final insightMaps = insights
          .map((i) => {
                'category': i.category,
                'content': i.content,
                'confidence': i.confidence,
              })
          .toList();

      // Call Cloud Function
      final response = await repo.sendCoachMessage(
        userMessage: message,
        context: context,
        recentHistory: history,
        insights: insightMaps,
      );

      // Replace loading message with actual response
      loadingMsg.content = response;
      loadingMsg.isLoading = false;
      loadingMsg.contextSnapshot = jsonEncode(context);
      await repo.addCoachMessage(loadingMsg);

      _assistantMessageCount++;
      ref.read(analyticsProvider).logAiCoachMessageSent();

      // Increment usage counter
      await ref.read(userProfileRepoProvider).incrementCoachMessageUsage();
      ref.invalidate(userProfileProvider);

      // Extract insights every 5 assistant messages
      if (_assistantMessageCount % 5 == 0) {
        _extractInsightsInBackground(history, insightMaps);
      }
    } catch (e) {
      loadingMsg.content = 'Sorry, I had trouble responding. Please try again.';
      loadingMsg.isLoading = false;
      await repo.addCoachMessage(loadingMsg);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _extractInsightsInBackground(
    List<Map<String, String>> history,
    List<Map<String, dynamic>> existingInsights,
  ) async {
    try {
      final repo = ref.read(primeRepoProvider);
      final newInsights = await repo.extractInsights(
        conversationHistory: history,
        existingInsights: existingInsights,
      );

      for (final raw in newInsights) {
        final insight = AiInsight()
          ..ts = DateTime.now()
          ..category = raw['category'] as String? ?? 'training_preference'
          ..content = raw['content'] as String? ?? ''
          ..confidence = (raw['confidence'] as num?)?.toDouble() ?? 0.5;
        await repo.saveAiInsight(insight);
      }

      ref.invalidate(aiInsightsProvider);
    } catch (_) {
      // Silently fail - insight extraction is non-critical
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('This will delete all coaching messages. Your AI insights will be kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(primeRepoProvider).clearCoachMessages();
    }
  }

  void _showUsageLimitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.chat_bubble_outline, size: 40, color: Colors.orange.shade600),
        title: const Text('Monthly Limit Reached'),
        content: Text(
          'You\'ve used all ${PremiumService.aiCoachMessageCap} AI coaching messages this month. '
          'Your messages reset at the start of each month.\n\n'
          'Need more? Message packs are coming soon!',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(coachMessagesProvider);
    final insightsAsync = ref.watch(aiInsightsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Coach'),
        backgroundColor: AppColors.background,
        actions: [
          // Usage counter chip
          ref.watch(userProfileProvider).when(
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              final service = ref.read(premiumServiceProvider);
              final remaining = service.coachMessagesRemaining(profile);
              final used = profile.aiCoachMessagesUsed;
              final cap = PremiumService.aiCoachMessageCap;
              final isLow = remaining <= 10;
              return Center(
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLow
                        ? Colors.orange.withOpacity(0.15)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$used/$cap',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isLow ? Colors.orange.shade700 : AppColors.primary,
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: PremiumGate(
        feature: PremiumFeature.aiCoaching,
        child: Column(
        children: [
          // AI Insights bar
          insightsAsync.when(
            data: (insights) {
              if (insights.isEmpty) return const SizedBox.shrink();
              return Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: insights.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => SizedBox(
                    width: 260,
                    child: AiInsightCard(
                      insight: insights[i],
                      onDismiss: () async {
                        await ref.read(primeRepoProvider).dismissInsight(insights[i].id);
                        ref.invalidate(aiInsightsProvider);
                      },
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    return CoachMessageBubble(
                      role: msg.role,
                      content: msg.content,
                      isLoading: msg.isLoading,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Something went wrong')),
            ),
          ),

          // Suggested prompts (show when no messages or few)
          messagesAsync.when(
            data: (messages) {
              if (messages.length > 4) return const SizedBox.shrink();
              return Container(
                height: 44,
                padding: const EdgeInsets.only(bottom: 4),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _suggestedPrompts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ActionChip(
                    label: Text(
                      _suggestedPrompts[i],
                      style: const TextStyle(fontSize: 13, color: AppColors.primary),
                    ),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    side: BorderSide.none,
                    onPressed: () => _sendMessage(_suggestedPrompts[i]),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Input bar
          ref.watch(userProfileProvider).when(
            data: (profile) {
              final limitReached = profile != null &&
                  !ref.read(premiumServiceProvider).canSendCoachMessage(profile);

              if (limitReached) {
                return Container(
                  padding: EdgeInsets.only(
                    left: 16, right: 16, top: 12,
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_outline, size: 16, color: Colors.orange.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Monthly message limit reached (${PremiumService.aiCoachMessageCap}/${PremiumService.aiCoachMessageCap}). Resets next month.',
                              style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: EdgeInsets.only(
                  left: 16, right: 8, top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        decoration: InputDecoration(
                          hintText: 'Ask your coach...',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                        enabled: !_sending,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: _sending
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send, color: AppColors.primary),
                      onPressed: _sending ? null : () => _sendMessage(_inputCtrl.text),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.chat_bubble_outline, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your AI Coach',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask about your nutrition, workouts, progress, or get personalized advice.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
