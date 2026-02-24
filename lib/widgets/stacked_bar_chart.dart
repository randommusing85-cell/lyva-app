import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Data for a single day in the stacked bar chart.
class StackedBarData {
  final String label;
  final double protein;
  final double carbs;
  final double fat;

  const StackedBarData({
    required this.label,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  double get total => protein + carbs + fat;
}

/// A stacked bar chart showing macro distribution per day
/// with an optional horizontal target line.
class StackedBarChart extends StatelessWidget {
  final List<StackedBarData> data;
  final double? targetLine;
  final String? targetLabel;

  const StackedBarChart({
    super.key,
    required this.data,
    this.targetLine,
    this.targetLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No data yet')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: CustomPaint(
            size: const Size(double.infinity, 140),
            painter: _StackedBarPainter(
              data: data,
              targetLine: targetLine,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Day labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: data.map((d) => SizedBox(
            width: 28,
            child: Text(
              d.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: AppColors.proteinGreen, label: 'Protein'),
            const SizedBox(width: 12),
            _LegendDot(color: AppColors.carbsYellow, label: 'Carbs'),
            const SizedBox(width: 12),
            _LegendDot(color: AppColors.fatPink, label: 'Fat'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _StackedBarPainter extends CustomPainter {
  final List<StackedBarData> data;
  final double? targetLine;

  _StackedBarPainter({required this.data, this.targetLine});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxTotal = data.map((d) => d.total).reduce(max);
    final maxValue = max(maxTotal, targetLine ?? 0.0) * 1.1;
    if (maxValue == 0) return;

    final barCount = data.length;
    final barWidth = (size.width / barCount) * 0.6;
    final gap = (size.width / barCount) * 0.4;

    for (int i = 0; i < barCount; i++) {
      final d = data[i];
      final centerX = (size.width / barCount) * i + (size.width / barCount) / 2;
      final left = centerX - barWidth / 2;

      // Fat (bottom)
      final fatHeight = (d.fat / maxValue) * size.height;
      final fatRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, size.height - fatHeight, barWidth, fatHeight),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      );
      canvas.drawRRect(fatRect, Paint()..color = AppColors.fatPink);

      // Carbs (middle)
      final carbsHeight = (d.carbs / maxValue) * size.height;
      final carbsRect = Rect.fromLTWH(
        left,
        size.height - fatHeight - carbsHeight,
        barWidth,
        carbsHeight,
      );
      canvas.drawRect(carbsRect, Paint()..color = AppColors.carbsYellow);

      // Protein (top)
      final proteinHeight = (d.protein / maxValue) * size.height;
      final proteinRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          left,
          size.height - fatHeight - carbsHeight - proteinHeight,
          barWidth,
          proteinHeight,
        ),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(proteinRect, Paint()..color = AppColors.proteinGreen);
    }

    // Target line
    if (targetLine != null && targetLine! > 0) {
      final targetY = size.height - (targetLine! / maxValue) * size.height;
      final dashPaint = Paint()
        ..color = Colors.grey.shade500
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      const dashWidth = 6.0;
      const dashSpace = 4.0;
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, targetY),
          Offset(min(startX + dashWidth, size.width), targetY),
          dashPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StackedBarPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.targetLine != targetLine;
  }
}
