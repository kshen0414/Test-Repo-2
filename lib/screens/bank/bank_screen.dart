import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:basic_ui_2/services/finverse_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/expense.dart';
import '../../models/receipt.dart';
import '../../providers/expense_provider.dart';
import '../../providers/receipt_provider.dart';
import '../../widgets/recent_transactions_widget.dart';
import '../bank/connect_bank_button.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  final FinverseService _finverseService = FinverseService();
  String? _errorMessage;
  Map<String, dynamic>? _accountsData;
  bool _isLoading = false;
  Timer? _pollingTimer;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userName = 'User'; // Default value

  @override
  void initState() {
    super.initState();
    _loadAccountsData(); // Load data from local storage on startup
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final User? user = _auth.currentUser;
    if (user != null &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      setState(() {
        _userName = user.displayName!;
      });
    }
  }

  // void _handleAccountsFetched(Map<String, dynamic> accounts) {
  //   setState(() {
  //     _accountsData = accounts;
  //     _isLoading = false;
  //   });

  //   // Check if data retrieval is still in progress
  //   if (_isDataRetrievalInProgress()) {
  //     _startPolling();
  //   }
  // }

  // void _handleError(String errorMessage) {
  //   setState(() {
  //     _errorMessage = errorMessage;
  //     _isLoading = false;
  //   });
  // }

  // bool _isDataRetrievalInProgress() {
  //   return _accountsData?['login_identity']?['status'] ==
  //       'DATA_RETRIEVAL_IN_PROGRESS';
  // }

  // void _startPolling() {
  //   _pollingTimer?.cancel();
  //   _pollingTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
  //     await _fetchAccountsData();
  //     if (!_isDataRetrievalInProgress()) {
  //       timer.cancel();
  //     }
  //   });
  // }

  // Future<void> _fetchAccountsData() async {
  //   print("Starting _fetchAccountsData");
  //   try {
  //     final accounts = await _finverseService.getAccounts();
  //     print("Accounts data fetched successfully");
  //     setState(() {
  //       _accountsData = accounts;
  //     });
  //   } catch (e) {
  //     print("Error in _fetchAccountsData: $e");
  //     _handleError('Failed to fetch accounts data: ${e.toString()}');
  //   }
  // }

  // Update the handleAccountsFetched method
  void _handleAccountsFetched(Map<String, dynamic> accounts) async {
    print("Raw API Response:");
    print(jsonEncode(accounts)); // Log the raw response for debugging

    setState(() {
      // If `_accountsData` already exists, merge the new accounts
      if (_accountsData != null && _accountsData!['accounts'] != null) {
        final existingAccounts = _accountsData!['accounts'] as List;
        final newAccounts = accounts['accounts'] as List;

        // Merge the accounts (avoid duplicates based on account_id)
        final mergedAccounts = [
          ...existingAccounts,
          ...newAccounts.where((newAccount) => !existingAccounts.any(
              (existing) => existing['account_id'] == newAccount['account_id']))
        ];

        _accountsData!['accounts'] = mergedAccounts;
      } else {
        // If no previous data, simply set the new data
        _accountsData = accounts;
      }
      _isLoading = false;
    });

    // Save the merged data locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accountsData', jsonEncode(_accountsData));
    print("Accounts data saved locally.");
  }

  // Update handleError to include debugging

  void _handleError(String errorMessage) {
    print("Error occurred: $errorMessage");
    setState(() {
      _errorMessage = errorMessage;
      _isLoading = false;
    });
  }

  bool _isDataRetrievalInProgress() {
    return _accountsData?['login_identity']?['status'] ==
        'DATA_RETRIEVAL_IN_PROGRESS';
  }

  bool _isRetrievingData = false;

  void _startPolling() {
    if (_isRetrievingData) return; // Avoid duplicate polling
    _isRetrievingData = true;
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        final accounts = await _finverseService.getAccounts();
        setState(() {
          _accountsData = accounts;

          // Check the status of data retrieval
          if (_accountsData?['login_identity']?['status'] == 'DATA_RETRIEVED') {
            _isRetrievingData = false;
            timer.cancel(); // Stop polling once complete
            print('Data retrieval complete.');
          } else {
            print('Data retrieval still in progress...');
          }
        });
      } catch (e) {
        print('Polling error: $e');
        _isRetrievingData = false;
        timer.cancel(); // Stop polling in case of error
      }
    });
  }

  // Future<void> _fetchAccountsData() async {
  //   print("Starting _fetchAccountsData");
  //   try {
  //     final accounts = await _finverseService.getAccounts();
  //     print("Accounts data fetched successfully: $accounts"); // Debug print
  //     setState(() {
  //       _accountsData = accounts;
  //     });
  //   } catch (e) {
  //     print("Error in _fetchAccountsData: $e");
  //     _handleError('Failed to fetch accounts data: ${e.toString()}');
  //   }
  // }

  Future<void> _fetchAccountsData() async {
    print("Starting _fetchAccountsData");
    try {
      final accounts = await _finverseService.getAccounts();

      // Log the full response
      print("Full Response Body: ${jsonEncode(accounts)}");

      // Check if 'accounts' is returned and log it specifically
      if (accounts.containsKey('accounts')) {
        print("Accounts Field: ${jsonEncode(accounts['accounts'])}");
      } else {
        print("No 'accounts' field in response.");
      }

      setState(() {
        _accountsData = accounts;
      });
    } catch (e) {
      // Log error details
      print("Error in _fetchAccountsData: $e");
      _handleError('Failed to fetch accounts data: ${e.toString()}');
    }
  }

  Widget _buildAccountsView() {
    if (_accountsData == null) {
      return Center(child: Text('No account data available'));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accounts Data:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _buildAccountsList(),
            _buildInstitutionInfo(),
            _buildLoginIdentityInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsList() {
    List accounts = _accountsData?['accounts'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Accounts:', style: TextStyle(fontWeight: FontWeight.bold)),
        accounts.isEmpty
            ? Text('No accounts available')
            : Column(
                children: accounts
                    .map((account) => Text(account.toString()))
                    .toList(),
              ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildInstitutionInfo() {
    Map<String, dynamic> institution = _accountsData?['institution'] ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Institution:', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Countries: ${institution['countries']}'),
        Text('ID: ${institution['institution_id']}'),
        Text('Name: ${institution['institution_name']}'),
        Text('Portal Name: ${institution['portal_name']}'),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildLoginIdentityInfo() {
    Map<String, dynamic> loginIdentity = _accountsData?['login_identity'] ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Login Identity:', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('Last Session ID: ${loginIdentity['last_session_id']}'),
        Text('Login Identity ID: ${loginIdentity['login_identity_id']}'),
        Text('Status: ${loginIdentity['status']}'),
        if (_isDataRetrievalInProgress())
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Data retrieval in progress. Please wait...',
              style: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  List<dynamic> _getTopRecentTransactions(List<Expense> expenses,
      List<Expense> expenseReceipts, List<Receipt> receipts) {
    // Combine all sources of transactions
    final allTransactions = [
      ...expenses,
      ...expenseReceipts,
      ...receipts,
    ];

    // Sort by date in descending order (most recent first)
    allTransactions.sort((a, b) {
      final dateA = a is Expense ? a.date : (a as Receipt).date;
      final dateB = b is Expense ? b.date : (b as Receipt).date;
      return dateB.compareTo(dateA); // Descending order
    });

    // Return the top 4 most recent transactions
    return allTransactions.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Access the providers
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final receiptProvider = Provider.of<ReceiptProvider>(context);

    // Fetch data from providers
    final expenses = expenseProvider.expenses;
    final expenseReceipts = expenseProvider.receipts; // From ExpenseProvider
    final receipts = receiptProvider.receipts; // From ReceiptProvider

    // Aggregate the top 4 most recent transactions
    final recentTransactions =
        _getTopRecentTransactions(expenses, expenseReceipts, receipts);

    // Calculate total expenses
    final totalExpenses =
        _calculateTotalExpenses(expenses, expenseReceipts, receipts);

    final List<Map<String, dynamic>> transactions = [
      {
        'icon': Icons.shopping_bag,
        'title': 'Shopping',
        'subtitle': 'Grocery Store',
        'amount': -320.50,
        'date': '2 hours ago',
      },
      {
        'icon': Icons.fastfood,
        'title': 'Food & Dining',
        'subtitle': 'Restaurant',
        'amount': -65.80,
        'date': 'Yesterday',
      },
      {
        'icon': Icons.local_gas_station,
        'title': 'Transport',
        'subtitle': 'Gas Station',
        'amount': -180.00,
        'date': 'Yesterday',
      },
      {
        'icon': Icons.account_balance,
        'title': 'Salary',
        'subtitle': 'Monthly Payment',
        'amount': 5000.00,
        'date': '3 days ago',
      },
    ];

    return Scaffold(
      // backgroundColor: Color(0xFF1A1A1A), // Dark background
      backgroundColor: Colors.white, // Dark background
      appBar: AppBar(
        title: Text('Home'),
        centerTitle: true,
        // backgroundColor: Color(0xFF2A2A21), // Dark app bar
        backgroundColor: Colors.white, // Dark app bar
        scrolledUnderElevation: 0, // Prevents elevation when scrolling
        elevation: 0, // No shadow
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(),
              SizedBox(height: 25),
              _buildBalance(
                  totalExpenses), // Pass total expenses to _buildBalance
              // _buildBalance(),
              SizedBox(height: 25),
              _buildDebitCards(),
              SizedBox(height: 25),
              // _buildRecentTransactions(),
              // RecentTransactionsWidget(transactions: transactions),
              RecentTransactionsWidget(transactions: recentTransactions),
              // We'll add other sections later
            ],
          ),
        ),
      ),
    );

    // return
    // _isLoading
    //     ? const Center(child: CircularProgressIndicator())
    //     : _accountsData != null
    //         ? _buildAccountsView()
    //         : Column(
    //             children: [
    //               Expanded(
    //                 child: Center(
    //                   child: Column(
    //                     mainAxisAlignment: MainAxisAlignment.center,
    //                     children: [
    //                       ConnectBankButton(
    //                         onAccountsFetched: _handleAccountsFetched,
    //                         onError: _handleError,
    //                       ),
    //                       if (_errorMessage != null)
    //                         Padding(
    //                           padding: const EdgeInsets.all(16.0),
    //                           child: Text(
    //                             _errorMessage!,
    //                             style: TextStyle(color: Colors.red),
    //                           ),
    //                         ),
    //                     ],
    //                   ),
    //                 ),
    //               ),
    //             ],
    //           );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome text taking up its own row
        Text(
          'Welcome Back, $_userName',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4), // Small spacing between rows

        // Dashboard row with notification icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Stack(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    size: 30,
                    color: Colors.blue,
                  ),
                  Positioned(
                    right: 5,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                // Add your notification screen navigation logic here
                print('Notifications tapped!');
              },
            ),
          ],
        ),
      ],
    );
  }

  double _calculateTotalExpenses(List<Expense> expenses,
      List<Expense> expenseReceipts, List<Receipt> receipts) {
    // Sum up all expenses and receipt amounts
    double total = 0;

    // Add expenses and expenseReceipts amounts
    total += expenses.fold(0, (sum, expense) => sum + expense.amount);
    total += expenseReceipts.fold(0, (sum, expense) => sum + expense.amount);

    // Add receipt amounts
    total += receipts.fold(0, (sum, receipt) => sum + receipt.amount);

    return total;
  }

  Widget _buildBalance(double totalExpenses) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Expenses',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'RM ${totalExpenses.toStringAsFixed(2)}', // Display total expenses
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                width: 120,
                child: ElevatedButton(
                  onPressed: () {
                    // Add analytics logic if needed
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text('Analytics'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebitCards() {
    final PageController _pageController = PageController();

    // Include all accounts dynamically
    // unccomment to show all acc including pbe
    // final List filteredAccounts = (_accountsData?['accounts'] ?? []);

    final List filteredAccounts =
        (_accountsData?['accounts'] ?? []).where((account) {
      // Include accounts with HKD currency or specific account names
      return account['balance']['currency'] == 'HKD' ||
          account['account_name'] == 'HKD Credit Card' ||
          account['account_name'] == 'HKD Statement Savings';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Cards',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: Colors.blue),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => Container(
                    height: 200,
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Add New Card',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        ConnectBankButton(
                          onAccountsFetched: _handleAccountsFetched,
                          onError: _handleError,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount:
                      filteredAccounts.isNotEmpty ? filteredAccounts.length : 1,
                  itemBuilder: (context, index) {
                    if (filteredAccounts.isNotEmpty) {
                      final account = filteredAccounts[index];
                      return GestureDetector(
                        onTap: () {
                          _showCardOptionsDialog(account);
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 8),
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.purple, Colors.blue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _accountsData?['institution']
                                            ?['institution_name'] ??
                                        'Bank',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    account['account_name'] ??
                                        'Unnamed Account',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account['account_number_masked'] ?? '',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Balance',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${account['balance']['currency']} ${account['balance']['raw']}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.credit_card,
                                  color: Colors.grey[400], size: 48),
                              SizedBox(height: 8),
                              Text(
                                'No cards added yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                'Click + to add a card',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 16),
              SmoothPageIndicator(
                controller: _pageController,
                count:
                    filteredAccounts.isNotEmpty ? filteredAccounts.length : 1,
                effect: WormEffect(
                  activeDotColor: Colors.orange,
                  dotColor: Colors.grey.shade400,
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadAccountsData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accountsJson = prefs.getString('accountsData');

    if (accountsJson != null) {
      setState(() {
        _accountsData = jsonDecode(accountsJson);
        print("Loaded accounts data from local storage.");
      });
    } else {
      print("No local accounts data found.");
    }
  }

  void _showCardOptionsDialog(Map<String, dynamic> account) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.grey[100],
          title: Center(
            child: Text(
              'Manage Card',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.credit_card,
                  size: 48,
                  color: Colors.blue,
                ),
                SizedBox(height: 16),
                Text(
                  'Do you want to delete this card?\n\n${account['account_name']}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment:
              MainAxisAlignment.center, // Center the row of buttons
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min, // Take minimum space needed
              children: [
                // Cancel Button
                SizedBox(
                  width: 100, // Fixed width for buttons
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16), // Space between buttons
                // Delete Button
                SizedBox(
                  width: 100, // Fixed width for buttons
                  child: ElevatedButton(
                    onPressed: () {
                      _deleteCard(account);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCard(Map<String, dynamic> account) async {
    setState(() {
      // Remove the selected account
      (_accountsData?['accounts'] as List).remove(account);
    });

    // Save updated data to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accountsData', jsonEncode(_accountsData));
    print('Card deleted and data updated locally.');
  }

  // Widget _buildRecentTransactions() {
  //   final List<Map<String, dynamic>> transactions = [
  //     {
  //       'icon': Icons.shopping_bag,
  //       'title': 'Shopping',
  //       'subtitle': 'Grocery Store',
  //       'amount': -320.50,
  //       'date': '2 hours ago',
  //     },
  //     {
  //       'icon': Icons.fastfood,
  //       'title': 'Food & Dining',
  //       'subtitle': 'Restaurant',
  //       'amount': -65.80,
  //       'date': 'Yesterday',
  //     },
  //     {
  //       'icon': Icons.local_gas_station,
  //       'title': 'Transport',
  //       'subtitle': 'Gas Station',
  //       'amount': -180.00,
  //       'date': 'Yesterday',
  //     },
  //     {
  //       'icon': Icons.account_balance,
  //       'title': 'Salary',
  //       'subtitle': 'Monthly Payment',
  //       'amount': 5000.00,
  //       'date': '3 days ago',
  //     },
  //   ];
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Header
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             'Recent Transactions',
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontSize: 20,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //           TextButton(
  //             onPressed: () {},
  //             child: Text(
  //               'See All',
  //               style: TextStyle(color: Colors.blue),
  //             ),
  //           ),
  //         ],
  //       ),
  //       SizedBox(height: 16),

  //       // Transactions List
  //       Column(
  //         children: transactions.map((transaction) {
  //           final bool isIncome = transaction['amount'] > 0;

  //           return Container(
  //             margin: EdgeInsets.only(bottom: 12),
  //             padding: EdgeInsets.all(16),
  //             decoration: BoxDecoration(
  //               color: Color(0xFF2A2A21),
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //             child: Row(
  //               children: [
  //                 // Icon
  //                 Container(
  //                   padding: EdgeInsets.all(10),
  //                   decoration: BoxDecoration(
  //                     color: Colors.blue.withOpacity(0.2),
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                   child: Icon(
  //                     transaction['icon'],
  //                     color: Colors.blue,
  //                     size: 24,
  //                   ),
  //                 ),
  //                 SizedBox(width: 16),

  //                 // Title and Subtitle
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         transaction['title'],
  //                         style: TextStyle(
  //                           color: Colors.white,
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.w500,
  //                         ),
  //                       ),
  //                       SizedBox(height: 4),
  //                       Row(
  //                         children: [
  //                           Text(
  //                             transaction['subtitle'],
  //                             style: TextStyle(
  //                               color: Colors.grey[400],
  //                               fontSize: 14,
  //                             ),
  //                           ),
  //                           SizedBox(width: 8),
  //                           Text(
  //                             '• ${transaction['date']}',
  //                             style: TextStyle(
  //                               color: Colors.grey[400],
  //                               fontSize: 14,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                 ),

  //                 // Amount
  //                 Text(
  //                   '${isIncome ? '+' : '-'}\$${transaction['amount'].abs().toStringAsFixed(2)}',
  //                   style: TextStyle(
  //                     color: isIncome ? Colors.green : Colors.red,
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         }).toList(),
  //       ),
  //     ],
  //   );
  // }
}
