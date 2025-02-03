// lib/services/dialog_service.dart

import 'package:flutter/material.dart';
import '../widgets/dialogs/scan_result_dialog.dart';

class DialogService {
  static Future<void> showScanResult(
    BuildContext context, {
    required String imagePath,
    required String scannedText,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ScanResultDialog(
        imagePath: imagePath,
        scannedText: scannedText,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    // Don't show dialog for cancellation
    if (message.toLowerCase().contains('cancel') || 
        message.toLowerCase().contains('cancelled')) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(  // Prevent back button from dismissing loading
        onWillPop: () async => false,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  // Add a method to dismiss loading if needed
  static void dismissLoading(BuildContext context) {
    Navigator.of(context).pop();
  }
}