// lib/screens/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'expenses_screen.dart';
import 'voice_recognition.dart';
import '../../providers/expense_provider.dart' hide Expense;
import '../../models/expense.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  

  void _addNewExpense(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ExpensesPage(
        isEditing: false, // This is a new expense
      ),
    );

    if (result != null && result is Expense) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      provider.addExpense(result);
    }
  }

  void _showExpensesPage(BuildContext context, Expense expense) async {
    if (expense.isVoiceInput) {
      // For voice input expenses, show the voice modal
      final result = await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => VoiceRecognitionScreen(
          isEditing: true,
          existingExpense: expense,
        ),
      );

      if (result != null) {
        if (result == 'delete') {
          Provider.of<ExpenseProvider>(context, listen: false)
              .removeExpense(expense.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (result is Expense) {
          final provider = Provider.of<ExpenseProvider>(context, listen: false);
          provider.removeExpense(expense.id);
          provider.addExpense(result);
        }
      }
    } else {
      // Manual data entry modal design (similar to the provided example)
      final result = await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => ExpensesPage(
          isEditing: true,
          existingExpense: expense,
        ),
      );

      if (result != null) {
        if (result == 'delete') {
          Provider.of<ExpenseProvider>(context, listen: false)
              .removeExpense(expense.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(milliseconds: 1000), // Set to 1.5 seconds
            ),
          );
        } else if (result is Expense) {
          final provider = Provider.of<ExpenseProvider>(context, listen: false);
          provider.removeExpense(expense.id);
          provider.addExpense(result);
        }
      }
    }
  }

  void _showVoiceRecognition(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Add this to make it expandable
      backgroundColor: Colors.transparent, // Make background transparent
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95, // Same size as expense input
        builder: (_, controller) => VoiceRecognitionScreen(),
      ),
    );

    if (result != null && result is Expense) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      provider.addExpense(result);
    }
  }

  // Add the method here
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

  Widget _buildExpenseItem(BuildContext context, Expense expense, {Key? key}) {
    IconData iconData;
    Color iconColor;

    if (expense.isReceipt) {
      iconData = Icons.receipt_long;
      iconColor = Colors.blue;
    } else {
      switch (expense.category.toLowerCase()) {
        case 'food':
          iconData = Icons.restaurant;
          iconColor = Colors.red;
          break;
        case 'drinks':
          iconData = Icons.local_cafe;
          iconColor = Colors.teal;
          break;
        case 'transport':
          iconData = Icons.directions_bus;
          iconColor = Colors.blue;
          break;
        case 'shopping':
          iconData = Icons.shopping_bag;
          iconColor = Colors.purple;
          break;
        case 'entertainment':
          iconData = Icons.sports_esports;
          iconColor = Colors.orange;
          break;
        case 'housing':
          iconData = Icons.home;
          iconColor = Colors.green;
          break;
        case 'electronics':
          iconData = Icons.phone_android;
          iconColor = Colors.lightBlue;
          break;
        case 'medical':
          iconData = Icons.medical_services;
          iconColor = Colors.pink;
          break;
        case 'misc.':
          iconData = Icons.more_horiz;
          iconColor = Colors.grey;
          break;
        case 'income':
          iconData = Icons.savings;
          iconColor = Colors.amber;
          break;
        default:
          iconData = Icons.shopping_bag;
          iconColor = Colors.grey;
      }
    }

    // Format time with AM/PM
    String period = expense.date.hour < 12 ? 'AM' : 'PM';
    int hour =
        expense.date.hour > 12 ? expense.date.hour - 12 : expense.date.hour;
    hour = hour == 0 ? 12 : hour;

    return InkWell(
      key:
          key, // Now 'key' is recognized because it's defined in the method's parameters
      onTap: () => _showExpensesPage(context, expense),
      child: ListTile(
        leading: SizedBox(
          width: 40, // Specify a reasonable width
          height: 40, // Specify a height if desired
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: iconColor),
          ),
        ),
        title: Text(expense.isReceipt ? 'Receipt' : expense.category),
        subtitle: Text(
          '${expense.date.day} ${_getMonthName(expense.date.month)} ${expense.date.year}, '
          '${hour.toString().padLeft(2, '0')}:${expense.date.minute.toString().padLeft(2, '0')} $period',
        ),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            () {
              final absoluteAmount = expense.amount.abs();
              final wholeNumber = absoluteAmount.floor();
              final decimal = ((absoluteAmount - wholeNumber) * 100).round();
              final formattedWhole =
                  _addThousandSeparators(wholeNumber.toString());
              final isIncome = expense.category.toLowerCase() == 'income';

              return '${isIncome ? '' : '-'}RM $formattedWhole.${decimal.toString().padLeft(2, '0')}';
            }(),
            style: TextStyle(
              color: expense.category.toLowerCase() == 'income'
                  ? Colors.green.shade600
                  : Colors.red.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _editExpense(BuildContext context, Expense expense) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ExpensesPage(
        isEditing: true,
        existingExpense: expense,
      ),
    );

    if (result != null) {
      if (result == 'delete') {
        // Handle deletion
        final provider = Provider.of<ExpenseProvider>(context, listen: false);
        provider.removeExpense(expense.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result is Expense) {
        // Handle update
        final provider = Provider.of<ExpenseProvider>(context, listen: false);
        provider.removeExpense(expense.id);
        provider.addExpense(result);
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          if (provider.expenses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/Manual_Expense.svg',
                      height: 320,
                      width: 320,
                      // colorFilter: ColorFilter.mode(
                      //   Colors.grey[400]!,
                      //   BlendMode.srcIn,
                      // ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'No Expenses Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add your first expense by tapping the + button',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: provider.expenses.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final expense = provider.expenses[index];
              return _buildExpenseItem(
                context,
                expense,
                key: ValueKey(expense.id), // Passing the key here
              );
            },
          );
        },
      ),
      floatingActionButton: ExpandableFab(
        distance: 80,
        children: [
          ActionButton(
            onPressed: () => _addNewExpense(context),
            icon: const Icon(Icons.format_size),
          ),
          ActionButton(
            onPressed: () => _showVoiceRecognition(context),
            icon: const Icon(Icons.mic),
          ),
        ],
      ),
    );
  }
}

@immutable
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    this.initialOpen,
    required this.distance,
    required this.children,
  });

  final bool? initialOpen;
  final double distance;
  final List<Widget> children;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = 90.0 / (count - 1);
    for (var i = 0, angleInDegrees = 0.0;
        i < count;
        i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 150),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 150),
          child: FloatingActionButton(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            onPressed: _toggle,
            elevation: 4,
            shape: const CircleBorder(),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}

@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.onPressed,
    required this.icon,
  });

  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: Colors.blue,
      elevation: 4,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        color: Colors.white,
      ),
    );
  }
}
