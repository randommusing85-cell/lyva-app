import 'dart:math';
import 'package:flutter/material.dart';

/// A dual-line chart widget displaying two data series with separate colors.
/// Used for body composition trends (weight + waist measurements).
class DualLineChart extends StatelessWidget {
  final List<double> data1;
  final List<double> data2;
  final Color color1;
  final Color color2;
  final String label1;
  final String label2;
  final List<String>? xLabels;

  const DualLineChart({
    super.key,
    required this.data1,
    required this.data2,
    required this.color1,
    required this.color2,
    this.label1 = '',
    this.label2 = '',
    this.xLabels,
  });

  @override
  Widget build(BuildContext context) {
    if (data1.isEmpty && data2.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('No data yet')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: CustomPaint(
            size: const Size(double.infinity, 140),
            painter: _DualLinePainter(
              data1: data1,
              data2: data2,
              color1: color1,
              color2: color2,
            ),
          ),
        ),
        if (label1.isNotEmpty || label2.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (label1.isNotEmpty) ...[
                  Container(
                    width: 10,
                    height: 3,
                    decoration: BoxDecoration(
                      color: color1,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(label1, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
                if (label1.isNotEmpty && label2.isNotEmpty) const SizedBox(width: 16),
                if (label2.isNotEmpty) ...[
                  Container(
                    width: 10,
                    height: 3,
                    decoration: BoxDecoration(
                      color: color2,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(label2, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _DualLinePainter extends CustomPainter {
  final List<double> data1;
  final List<double> data2;
  final Color color1;
  final Color color2;

  _DualLinePainter({
    required this.data1,
    required this.data2,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawLine(canvas, size, data1, color1);
    _drawLine(canvas, size, data2, color2);
  }

  void _drawLine(Canvas canvas, Size size, List<double> data, Color color) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final allValues = [...data1, ...data2].where((v) => v > 0).toList();
    if (allValues.isEmpty) return;

    final minVal = allValues.reduce(min) - 1;
    final maxVal = allValues.reduce(max) + 1;
    final range = maxVal - minVal;
    if (range == 0) return;

    final path = Path();
    final points = <Offset>[];
    final count = data.length;

    for (int i = 0; i < count; i++) {
      if (data[i] <= 0) continue;
      final x = count == 1 ? size.width / 2 : size.width * i / (count - 1);
      final y = size.height - (size.height * (data[i] - minVal) / range);
      points.add(Offset(x, y));

      if (points.length == 1) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DualLinePainter oldDelegate) {
    return oldDelegate.data1 != data1 || oldDelegate.data2 != data2;
  }
}
