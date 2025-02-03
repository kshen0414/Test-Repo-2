import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  List<Expense> _receipts = [];
  static const String _expensesKey = 'expenses';
  static const String _receiptsKey = 'receipts';
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  List<Expense> get expenses => _expenses;
  List<Expense> get receipts => _receipts;

  // New initialization method with error handling
  Future<void> initializeData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load data sequentially to avoid parallel errors
      await _loadExpenses();
      await _loadReceipts();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error initializing data: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? expensesJson = prefs.getString(_expensesKey);
      if (expensesJson != null) {
        final List<dynamic> decodedList = jsonDecode(expensesJson);
        _expenses = decodedList
            .where((item) => item != null) // Filter out null items
            .map((item) {
              try {
                return Expense.fromMap(item);
              } catch (e) {
                print('Error parsing expense: $e');
                return null;
              }
            })
            .where((expense) => expense != null) // Filter out failed parsings
            .cast<Expense>()
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading expenses: $e');
    }
  }

  Future<void> _loadReceipts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? receiptsJson = prefs.getString(_receiptsKey);
      if (receiptsJson != null) {
        final List<dynamic> decodedList = jsonDecode(receiptsJson);
        _receipts = decodedList
            .where((item) => item != null) // Filter out null items
            .map((item) {
              try {
                return Expense.fromMap(item);
              } catch (e) {
                print('Error parsing receipt: $e');
                return null;
              }
            })
            .where((receipt) => receipt != null) // Filter out failed parsings
            .cast<Expense>()
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading receipts: $e');
    }
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = jsonEncode(_expenses.map((e) => e.toMap()).toList());
    await prefs.setString(_expensesKey, expensesJson);
  }

  Future<void> _saveReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    final receiptsJson = jsonEncode(_receipts.map((e) => e.toMap()).toList());
    await prefs.setString(_receiptsKey, receiptsJson);
  }

  void addExpense(Expense expense) {
    _expenses.insert(0, expense);
    _saveExpenses();
    notifyListeners();
  }

  void addReceipt(Expense receipt) {
    _receipts.insert(0, receipt);
    _saveReceipts();
    notifyListeners();
  }

  void removeExpense(String id) {
    _expenses.removeWhere((expense) => expense.id == id);
    _saveExpenses();
    notifyListeners();
  }

  void removeReceipt(String id) {
    _receipts.removeWhere((receipt) => receipt.id == id);
    _saveReceipts();
    notifyListeners();
  }
}