import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/theme.dart';
import 'item_model.dart';

Item? findItemByBarcode(List<Item> items, String code) {
  final wanted = code.trim();
  for (final item in items) {
    if (item.barcode == wanted) return item;
  }
  return null;
}

Future<void> showBarcodeScanner(
  BuildContext context, {
  required List<Item> items,
  required ValueChanged<Item> onItem,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ScannerSheet(items: items, onItem: onItem),
  );
}

class _ScannerSheet extends StatefulWidget {
  const _ScannerSheet({required this.items, required this.onItem});

  final List<Item> items;
  final ValueChanged<Item> onItem;

  @override
  State<_ScannerSheet> createState() => _ScannerSheetState();
}

class _ScannerSheetState extends State<_ScannerSheet> {
  static const _repeatDelay = Duration(seconds: 2);

  final _controller = MobileScannerController();
  String? _lastCode;
  DateTime _lastScanAt = DateTime.fromMillisecondsSinceEpoch(0);
  String _message = '';
  bool _isError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (code == null) return;

    final now = DateTime.now();
    if (code == _lastCode && now.difference(_lastScanAt) < _repeatDelay) {
      return;
    }
    _lastCode = code;
    _lastScanAt = now;

    final item = findItemByBarcode(widget.items, code);
    if (item == null) {
      setState(() {
        _message = 'No item with barcode $code';
        _isError = true;
      });
      return;
    }
    widget.onItem(item);
    HapticFeedback.lightImpact();
    setState(() {
      _message = 'Added ${item.name}';
      _isError = false;
    });
  }

  Widget _cameraError(MobileScannerException error) {
    final message = error.errorCode == MobileScannerErrorCode.permissionDenied
        ? 'Camera permission is needed to scan. Allow it in the phone settings, or add the item by typing its barcode.'
        : 'The camera is not available. Add the item by typing its barcode.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Scan barcode',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 220,
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                      errorBuilder: (_, error) => _cameraError(error),
                    ),
                    Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.72,
                        heightFactor: 0.5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.accent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 22,
              child: Text(
                _message,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _isError
                      ? Theme.of(context).colorScheme.error
                      : AppColors.approved,
                ),
              ),
            ),
            const Text(
              'Each scan adds the item to the invoice.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
