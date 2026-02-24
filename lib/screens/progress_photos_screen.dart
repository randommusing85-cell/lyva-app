import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/progress_photo.dart';
import '../services/premium_service.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_gate.dart';

class ProgressPhotosScreen extends ConsumerStatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  ConsumerState<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends ConsumerState<ProgressPhotosScreen> {
  final _picker = ImagePicker();
  bool _capturing = false;

  Future<void> _addPhoto(ImageSource source) async {
    if (_capturing) return;
    setState(() => _capturing = true);

    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (xFile == null) {
        setState(() => _capturing = false);
        return;
      }

      // Save to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/progress_photos');
      if (!await photosDir.exists()) await photosDir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = '${photosDir.path}/photo_$timestamp.jpg';
      await File(xFile.path).copy(savedPath);

      // Save to Isar
      final photo = ProgressPhoto()
        ..ts = DateTime.now()
        ..imagePath = savedPath;

      final repo = ref.read(primeRepoProvider);
      await repo.saveProgressPhoto(photo);
      ref.read(analyticsProvider).logProgressPhotoTaken();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save photo')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _addPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _addPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(progressPhotosProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Progress Photos'),
        backgroundColor: AppColors.background,
      ),
      body: PremiumGate(
        feature: PremiumFeature.progressPhotos,
        child: photosAsync.when(
          data: (photos) {
            if (photos.isEmpty) return _buildEmptyState();

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3 / 4,
              ),
              itemCount: photos.length,
              itemBuilder: (_, i) => _PhotoTile(
                photo: photos[i],
                onTap: () => Navigator.pushNamed(
                  context,
                  '/progress-photo-detail',
                  arguments: photos[i],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Something went wrong')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _capturing ? null : _showSourcePicker,
        backgroundColor: AppColors.primary,
        child: _capturing
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.camera_alt, color: Colors.white),
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
                color: AppColors.seasonAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(Icons.camera_alt, size: 36, color: AppColors.seasonAccent),
            ),
            const SizedBox(height: 16),
            const Text(
              'Track Your Transformation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take progress photos to visually track your fitness journey. Get AI-powered body analysis.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showSourcePicker,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Take First Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final ProgressPhoto photo;
  final VoidCallback onTap;

  const _PhotoTile({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photo.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.broken_image, color: AppColors.textMuted),
              ),
            ),
            // Date label at bottom
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                color: Colors.black54,
                child: Text(
                  DateFormat('MMM d').format(photo.ts),
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Analysis badge
            if (photo.analysisComplete)
              Positioned(
                top: 4, right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
