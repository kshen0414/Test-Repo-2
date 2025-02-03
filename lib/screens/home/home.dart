import 'dart:async';
// import 'dart:io';
import 'package:basic_ui_2/screens/bank/bank_screen.dart';
import 'package:basic_ui_2/screens/history/history_screen.dart';
import 'package:basic_ui_2/screens/profile/profile_screen.dart';
import 'package:basic_ui_2/services/document_scanner_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:basic_ui_2/services/finverse_service.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/dialog_service.dart';
import '../../widgets/bottom_navigation.dart';
// import '../bank/connect_bank_button.dart';
import '../transaction/transactions_screen.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final DocumentScannerService _scannerService = DocumentScannerService();
  String _scannedText = '';
  String _imagePath = '';
  bool _isProcessing = false;

  Future<void> _onCameraPressed() async {
    try {
      DialogService.showLoading(context);

      final result = await _scannerService.startScanning();

      if (mounted) {
        Navigator.pop(context); // Dismiss loading

        if (result['success']) {
          await DialogService.showScanResult(
            context,
            imagePath: result['imagePath'],
            scannedText: result['scannedText'],
          );
        } else {
          DialogService.showError(context, result['error']);
        }
      }
    } on PlatformException catch (e) {
      // Handle specific cancellation error
      if (e.code == 'DocumentScanner' && e.message == 'Operation cancelled') {
        DialogService.showError(context, 'You canceled the scan.');
      } else {
        DialogService.showError(context, 'An error occurred: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        DialogService.showError(context, 'An unexpected error occurred: $e');
      }
    }
  }

  @override
  void dispose() {
    _scannerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavigationProvider(),
      child: Consumer<NavigationProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: IndexedStack(
              index: provider.currentIndex > 2
                  ? provider.currentIndex - 1
                  : provider.currentIndex,
              children: [
                const BankScreen(),
                const HistoryScreen(),
                TransactionsScreen(),
                const ProfileScreen(),
              ],
            ),
            floatingActionButton: Transform.translate(
              offset: const Offset(0, 8),
              child: Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  heroTag: 'mainCameraFAB',
                  backgroundColor: Colors.blue,
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: _onCameraPressed,
                ),
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: const MyBottomNavigationBar(),
          );
        },
      ),
    );
  }
}
