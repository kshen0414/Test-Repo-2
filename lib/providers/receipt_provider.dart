import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/receipt.dart';

class ReceiptProvider extends ChangeNotifier {
  List<Receipt> _receipts = [];
  static const String _receiptsKey = 'receipts';
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  List<Receipt> get receipts => _receipts;

  Future<void> initializeData() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _loadReceipts();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error initializing data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadReceipts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? receiptsJson = prefs.getString(_receiptsKey);
      if (receiptsJson != null) {
        final List<dynamic> decodedList = jsonDecode(receiptsJson);
        _receipts = decodedList
            .where((item) => item != null)
            .map((item) {
              try {
                return Receipt.fromMap(item);
              } catch (e) {
                print('Error parsing receipt: $e');
                return null;
              }
            })
            .where((receipt) => receipt != null)
            .cast<Receipt>()
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading receipts: $e');
    }
  }

  Future<void> _saveReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    final receiptsJson = jsonEncode(_receipts.map((r) => r.toMap()).toList());
    await prefs.setString(_receiptsKey, receiptsJson);
  }

  void addReceipt(Receipt receipt) {
    _receipts.insert(0, receipt);
    _saveReceipts();
    notifyListeners();
  }

  void removeReceipt(String id) {
    _receipts.removeWhere((receipt) => receipt.id == id);
    _saveReceipts();
    notifyListeners();
  }

  /// Update an existing receipt by its ID
  void updateReceipt(String id, Receipt updatedReceipt) {
    final index = _receipts.indexWhere((receipt) => receipt.id == id);
    if (index != -1) {
      _receipts[index] = updatedReceipt; // Update the receipt
      _saveReceipts(); // Save the updated list
      notifyListeners(); // Notify listeners to update the UI
    }
  }
}