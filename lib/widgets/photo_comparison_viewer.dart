import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/progress_photo.dart';
import '../theme/app_theme.dart';

class PhotoComparisonViewer extends StatelessWidget {
  final ProgressPhoto leftPhoto;
  final ProgressPhoto rightPhoto;

  const PhotoComparisonViewer({
    super.key,
    required this.leftPhoto,
    required this.rightPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.file(
                    File(leftPhoto.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dateFormat.format(leftPhoto.ts),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.file(
                    File(rightPhoto.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dateFormat.format(rightPhoto.ts),
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
