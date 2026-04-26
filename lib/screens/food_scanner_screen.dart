import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/food_item.dart';
import '../services/food_scanner_service.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';

/// Result returned to the caller when a food item is selected.
class FoodScanResult {
  final String name;
  final int proteinG;
  final int carbsG;
  final int fatG;

  const FoodScanResult({
    required this.name,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

class FoodScannerScreen extends ConsumerStatefulWidget {
  const FoodScannerScreen({super.key});

  @override
  ConsumerState<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends ConsumerState<FoodScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  final FoodScannerService _ocrService = FoodScannerService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  String? _statusMessage;
  FoodItem? _foundItem;
  bool _barcodeProcessed = false;

  @override
  void dispose() {
    _cameraController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_barcodeProcessed || _isLoading) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() {
      _barcodeProcessed = true;
      _isLoading = true;
      _statusMessage = 'Looking up barcode $barcode...';
    });

    try {
      // 1. Check local DB
      final repo = ref.read(lyvaRepoProvider);
      var item = await repo.getFoodByBarcode(barcode);

      if (item == null) {
        // 2. Check API
        final api = ref.read(foodApiServiceProvider);
        item = await api.lookupBarcode(barcode);

        // 3. Cache if found
        if (item != null) {
          await repo.saveFoodItem(item);
        }
      }

      setState(() {
        _isLoading = false;
        _foundItem = item;
        _statusMessage = item == null ? 'Product not found for barcode $barcode' : null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error looking up barcode';
      });
    }
  }

  Future<void> _scanNutritionLabel() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Reading nutrition label...';
    });

    try {
      final item = await _ocrService.scanNutritionLabel(File(picked.path));
      if (item != null) {
        // Cache the OCR result
        final repo = ref.read(lyvaRepoProvider);
        await repo.saveFoodItem(item);
      }

      setState(() {
        _isLoading = false;
        _foundItem = item;
        _statusMessage = item == null ? 'Could not read nutrition info from label' : null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error reading label';
      });
    }
  }

  void _useItem(FoodItem item) {
    Navigator.pop(
      context,
      FoodScanResult(
        name: item.name,
        proteinG: item.proteinG,
        carbsG: item.carbsG,
        fatG: item.fatG,
      ),
    );
  }

  void _resetScan() {
    setState(() {
      _foundItem = null;
      _statusMessage = null;
      _barcodeProcessed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Food'),
        actions: [
          TextButton.icon(
            onPressed: _scanNutritionLabel,
            icon: const Icon(Icons.document_scanner, color: Colors.white, size: 18),
            label: const Text('OCR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview
          Expanded(
            flex: 3,
            child: _foundItem != null
                ? _buildResultCard(_foundItem!)
                : Stack(
                    children: [
                      MobileScanner(
                        controller: _cameraController,
                        onDetect: _onBarcodeDetected,
                      ),
                      // Scan overlay
                      Center(
                        child: Container(
                          width: 280,
                          height: 160,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Status / loading area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.black,
            child: Column(
              children: [
                if (_isLoading)
                  const CircularProgressIndicator(color: AppColors.primary),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  if (_foundItem == null && !_isLoading) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _resetScan,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ],
                if (!_isLoading && _statusMessage == null && _foundItem == null)
                  const Text(
                    'Point camera at a barcode\nor tap OCR to scan a nutrition label',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(FoodItem item) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (item.brand != null) ...[
            const SizedBox(height: 4),
            Text(
              item.brand!,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Per serving (${item.servingSizeG}g)',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MacroChip('P', item.proteinG, AppColors.proteinGreen),
              const SizedBox(width: 12),
              _MacroChip('C', item.carbsG, AppColors.carbsYellow),
              const SizedBox(width: 12),
              _MacroChip('F', item.fatG, AppColors.fatPink),
              const SizedBox(width: 16),
              Text(
                '${item.calories} kcal',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetScan,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Scan Again'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _useItem(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Use This'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _MacroChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: ${value}g',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
