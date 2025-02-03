// screens/history/expenses_screen.dart
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../models/expense.dart';

class ExpensesPage extends StatefulWidget {
  final bool isEditing;
  final Expense? existingExpense;

  const ExpensesPage({
    super.key,
    this.isEditing = false,
    this.existingExpense,
  });

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final TextEditingController _noteController = TextEditingController();

   @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  late DateTime selectedDate;
  late DateTime displayedMonth;
  late final tz.Location malaysiaTime;

  static const int MAX_WHOLE_DIGITS = 10;
  static const int MAX_DECIMAL_PLACES = 2;

  String _amount = '0';
  bool _hasDecimal = false;
  bool _isNegative = false;

  String? _selectedCategory;

  void _handleCategorySelected(String category) {
    setState(() {
      _selectedCategory = _selectedCategory == category ? null : category;
    });
  }

  // Getter for formatted display amount
  String get formattedAmount {
    if (_amount == '0') return 'RM0';

    // Handle decimal formatting
    String displayAmount = _amount;
    if (_hasDecimal && !_amount.contains('.')) {
      displayAmount = '$_amount.';
    }

    // Add thousand separators
    final parts = displayAmount.split('.');
    parts[0] = _addThousandSeparators(parts[0]);

    return 'RM${parts.join('.')}';
  }

  // Add thousand separators to the whole number part
  String _addThousandSeparators(String value) {
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && (value.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(value[i]);
    }
    return buffer.toString();
  }

  // Validate if we can add more digits
  bool _canAddDigit(String currentValue, String newDigit) {
    if (!_hasDecimal) {
      return currentValue.replaceAll(',', '').length < MAX_WHOLE_DIGITS;
    }

    final parts = currentValue.split('.');
    if (parts.length > 1) {
      return parts[1].length < MAX_DECIMAL_PLACES;
    }
    return true;
  }

  // Handle numeric input
  void _handleNumberInput(String value) {
    setState(() {
      switch (value) {
        case '⌫':
          _handleBackspace();
          break;
        case '.':
          _handleDecimalPoint();
          break;
        case '+':
          _isNegative = false;
          break;
        case '-':
          _isNegative = !_isNegative;
          break;
        case 'MYR':
          break;
        case '✓':
          _handleConfirm();
          break;
        default:
          _handleDigit(value);
      }
    });
  }

  void _handleBackspace() {
    if (_amount.length > 1) {
      if (_amount[_amount.length - 1] == '.') {
        _hasDecimal = false;
      }
      _amount = _amount.substring(0, _amount.length - 1);
      if (_amount.isEmpty || _amount == '-') _amount = '0';
    } else {
      _amount = '0';
      _hasDecimal = false;
    }
  }

  void _handleDecimalPoint() {
    if (!_hasDecimal) {
      _hasDecimal = true;
      _amount = '$_amount.';
    }
  }

  void _handleDigit(String digit) {
    if (!_canAddDigit(_amount, digit)) {
      // Optionally show feedback that max digits reached
      return;
    }

    if (_amount == '0' && !_hasDecimal) {
      _amount = digit;
    } else {
      _amount = '$_amount$digit';
    }
  }


  void _handleConfirm() {
    try {
      final numericAmount = double.parse(_amount) * (_isNegative ? -1 : 1);

      // Check for zero amount
      if (numericAmount == 0) {
        // Calculate bottom padding based on keypad height
        final keypadHeight = 5 * 56.0; // 4 rows * button height
        final bottomPadding =
            MediaQuery.of(context).viewInsets.bottom + keypadHeight;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Amount cannot be zero'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: bottomPadding,
              left: 16,
              right: 16,
            ),
          ),
        );
        return;
      }

      // Get current time in Malaysia timezone
      final now = tz.TZDateTime.now(malaysiaTime);

      // Combine selected date with current time
      final dateTime = tz.TZDateTime(
        malaysiaTime,
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      );

      final expense = Expense(
        amount: numericAmount,
        category: _selectedCategory ?? 'Food',
        date: dateTime,
      );

      Navigator.pop(context, expense);
    } catch (e) {
      print('Error parsing amount: $e');
      // Use same dynamic positioning for error message
      final keypadHeight = 4 * 56.0;
      final bottomPadding =
          MediaQuery.of(context).viewInsets.bottom + keypadHeight;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid amount'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: bottomPadding,
            left: 16,
            right: 16,
          ),
        ),
      );
    }
  }

  // Update the build method for the amount display
  Widget _buildAmountDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.attach_money, color: Colors.grey, size: 30),
              const SizedBox(width: 8),
              const Text(
                'Cash',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                _isNegative ? '-${formattedAmount}' : formattedAmount,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialize timezone data
    tz.initializeTimeZones();

    // Get Malaysia time
    malaysiaTime = tz.getLocation('Asia/Kuala_Lumpur');

    // final now = tz.TZDateTime.now(malaysiaTime);

    // selectedDate = DateTime(now.year, now.month, now.day);
    // displayedMonth = DateTime(selectedDate.year, selectedDate.month);

    // Print for debugging
    // print('Malaysia Time: ${now.toString()}');
    // print('Selected Date: ${selectedDate.toString()}');

    if (widget.isEditing && widget.existingExpense != null) {
      // Pre-fill values for editing
      _amount = widget.existingExpense!.amount.abs().toStringAsFixed(2);
      _isNegative = widget.existingExpense!.amount < 0;
      _selectedCategory = widget.existingExpense!.category;
      selectedDate = widget.existingExpense!.date;
      _hasDecimal = _amount.contains('.');
    } else {
      // Default values for new expense
      final now = tz.TZDateTime.now(malaysiaTime);
      selectedDate = DateTime(now.year, now.month, now.day);

      // Set the default category to "Food"
      _selectedCategory = 'Food';
    }
    displayedMonth = DateTime(selectedDate.year, selectedDate.month);
  }

  bool _isSelectedDate(DateTime date) {
    return date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;
  }

  bool _isToday(DateTime date) {
    final now = tz.TZDateTime.now(malaysiaTime);
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    // final malaysiaTime = tz.getLocation('Asia/Kuala_Lumpur');
    // final now = tz.TZDateTime.now(malaysiaTime);
    // return date.year == now.year &&
    //     date.month == now.month &&
    //     date.day == now.day;
  }

  String _getFormattedMonth() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[displayedMonth.month - 1]} ${displayedMonth.year}';
  }

  List<DateTime> _getCalendarDays() {
    final List<DateTime> days = [];

    // First day of the month
    final firstDay = DateTime(displayedMonth.year, displayedMonth.month, 1);

    // Find the first Sunday before or on the first day of the month
    final firstSunday = firstDay.subtract(Duration(days: firstDay.weekday % 7));

    // Generate 42 days (6 weeks)
    for (var i = 0; i < 42; i++) {
      days.add(firstSunday.add(Duration(days: i)));
    }

    return days;
  }

  Future<void> _selectDate(BuildContext context) async {
    // final malaysiaTime = tz.getLocation('Asia/Kuala_Lumpur');
    // final now = tz.TZDateTime.now(malaysiaTime);
    // final today = DateTime(now.year, now.month, now.day);

    final DateTime? picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 400,
              color: Colors.grey[850],
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            final now = tz.TZDateTime.now(malaysiaTime);
                            final today =
                                DateTime(now.year, now.month, now.day);
                            Navigator.pop(context, today);
                          },
                          child: const Text(
                            'Today',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left,
                                  color: Colors.amber),
                              onPressed: () {
                                setModalState(() {
                                  displayedMonth = DateTime(
                                    displayedMonth.year,
                                    displayedMonth.month - 1,
                                  );
                                });
                              },
                            ),
                            Text(
                              _getFormattedMonth(),
                              style: const TextStyle(color: Colors.amber),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right,
                                  color: Colors.amber),
                              onPressed: () {
                                setModalState(() {
                                  displayedMonth = DateTime(
                                    displayedMonth.year,
                                    displayedMonth.month + 1,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        'Sun',
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                      ]
                          .map((day) => Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                      ),
                      itemCount: 42, // 6 weeks * 7 days
                      itemBuilder: (context, index) {
                        final days = _getCalendarDays();
                        final date = days[index];
                        final isCurrentMonth =
                            date.month == displayedMonth.month;
                        final nowInMalaysia = tz.TZDateTime.now(malaysiaTime);
                        final isToday = date.year == nowInMalaysia.year &&
                            date.month == nowInMalaysia.month &&
                            date.day == nowInMalaysia.day;
                        final isSelected = date.year == selectedDate.year &&
                            date.month == selectedDate.month &&
                            date.day == selectedDate.day;

                        return TextButton(
                          onPressed: () {
                            Navigator.pop(context, date);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: isSelected ? Colors.amber : null,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(35.0),
                            ),
                          ),
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.black // Selected date text is black
                                  : isCurrentMonth
                                      ? (isToday ? Colors.amber : Colors.white)
                                      : Colors.grey[600],
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        displayedMonth = DateTime(picked.year, picked.month);
      });
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.transparent,
    body: DraggableScrollableSheet(
      initialChildSize: 0.95,
      builder: (_, controller) => Container(
        color: Colors.white,
        child: Column(
          children: [
            AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              // AppBar stays exactly the same
              title: Row(
                children: [
                  Expanded(
                    child: Container(
                      width: 250,
                      child: TextButton(
                        onPressed: () => _selectDate(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isToday(selectedDate)
                                  ? 'Today'
                                  : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (widget.isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Expense'),
                            content: const Text('Are you sure you want to delete this expense?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context, 'delete');
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildAmountDisplay(),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 5,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.1,
                      children: [
                        _CategoryItem(
                          icon: Icons.restaurant,
                          label: 'Food',
                          color: Colors.red,
                          isSelected: _selectedCategory == 'Food',
                          onTap: () => _handleCategorySelected('Food'),
                        ),
                        _CategoryItem(
                          icon: Icons.local_cafe,
                          label: 'Drinks',
                          color: Colors.teal,
                          isSelected: _selectedCategory == 'Drinks',
                          onTap: () => _handleCategorySelected('Drinks'),
                        ),
                        _CategoryItem(
                          icon: Icons.directions_bus,
                          label: 'Transport',
                          color: Colors.blue,
                          isSelected: _selectedCategory == 'Transport',
                          onTap: () => _handleCategorySelected('Transport'),
                        ),
                        _CategoryItem(
                          icon: Icons.shopping_bag,
                          label: 'Shopping',
                          color: Colors.purple,
                          isSelected: _selectedCategory == 'Shopping',
                          onTap: () => _handleCategorySelected('Shopping'),
                        ),
                        _CategoryItem(
                          icon: Icons.sports_esports,
                          label: 'Entertainment',
                          color: Colors.orange,
                          isSelected: _selectedCategory == 'Entertainment',
                          onTap: () => _handleCategorySelected('Entertainment'),
                        ),
                        _CategoryItem(
                          icon: Icons.home,
                          label: 'Housing',
                          color: Colors.green,
                          isSelected: _selectedCategory == 'Housing',
                          onTap: () => _handleCategorySelected('Housing'),
                        ),
                        _CategoryItem(
                          icon: Icons.phone_android,
                          label: 'Electronics',
                          color: Colors.lightBlue,
                          isSelected: _selectedCategory == 'Electronics',
                          onTap: () => _handleCategorySelected('Electronics'),
                        ),
                        _CategoryItem(
                          icon: Icons.medical_services,
                          label: 'Medical',
                          color: Colors.pink,
                          isSelected: _selectedCategory == 'Medical',
                          onTap: () => _handleCategorySelected('Medical'),
                        ),
                        _CategoryItem(
                          icon: Icons.more_horiz,
                          label: 'Misc.',
                          color: Colors.grey,
                          isSelected: _selectedCategory == 'Misc.',
                          onTap: () => _handleCategorySelected('Misc.'),
                        ),
                        _CategoryItem(
                          icon: Icons.savings,
                          label: 'Income',
                          color: Colors.amber,
                          isSelected: _selectedCategory == 'Income',
                          onTap: () => _handleCategorySelected('Income'),
                        ),
                      ],
                    ),
                  ),
                  // Small spacer before note field
                  const SizedBox(height: 8),
                  // Non-editable note field
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_note, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'Tap to Add a Note',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    color: Colors.grey[850],
                    child: Column(
                      children: [
                        _buildNumberRow(['7', '8', '9', '⌫']),
                        _buildNumberRow(['4', '5', '6', '+']),
                        _buildNumberRow(['1', '2', '3', '-']),
                        _buildNumberRow(['MYR', '0', '.', '✓']),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // Update the number pad row builder
  Widget _buildNumberRow(List<String> buttons) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons
          .map((button) => Expanded(
                child: TextButton(
                  onPressed: () => _handleNumberInput(button),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  child: Text(
                    button,
                    style: TextStyle(
                      fontSize: 24,
                      color: button == '⌫' ||
                              button == '+' ||
                              button == '-' ||
                              button == '✓'
                          ? Colors.amber
                          : Colors.white,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  height: 1.0,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;

  const _TimeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Chip(
        label: Text(label),
        backgroundColor: Colors.grey[200],
      ),
    );
  }
}
