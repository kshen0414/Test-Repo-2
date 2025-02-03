// lib/widgets/dialogs/scan_result_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/receipt_provider.dart';
import '../../models/receipt.dart';
import '../../services/text_extraction_service.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class ScanResultDialog extends StatefulWidget {
  final String imagePath;
  final String scannedText;
  final Receipt? receipt;

  const ScanResultDialog({
    Key? key,
    required this.imagePath,
    required this.scannedText,
    this.receipt, // Initialize to null by default for new receipt creation
  }) : super(key: key);

  @override
  State<ScanResultDialog> createState() => _ScanResultDialogState();
}

class PaymentMethod {
  final String name;
  final String subtitle;
  final IconData icon;

  PaymentMethod({
    required this.name,
    required this.subtitle,
    required this.icon,
  });
}

// Add AmountEditor here
class AmountEditor extends StatefulWidget {
  final String initialAmount;
  final ValueChanged<String> onChanged;
  final String label;

  const AmountEditor({
    Key? key,
    required this.initialAmount,
    required this.onChanged,
    required this.label,
  }) : super(key: key);

  @override
  State<AmountEditor> createState() => _AmountEditorState();
}

class _AmountEditorState extends State<AmountEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    String initialValue = widget.initialAmount.replaceAll('MYR ', '');
    _controller = TextEditingController(text: initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    // _merchantNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'MYR ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (value) {
                    widget.onChanged('MYR $value');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScanResultDialogState extends State<ScanResultDialog> {
  final TextExtractionService _extractionService = TextExtractionService();
  late TextEditingController _merchantNameController;
  String storeName = 'Store Name';
  String totalAmount = 'MYR 50.50';
  String taxAmount = 'MYR 0.00';
  String date = 'Nov 9, 2024';
  bool isLoading = true;

  // bool _isEditingPaymentMethods = false;

  @override
  void dispose() {
    _merchantNameController.dispose();
    super.dispose();
  }

  void _saveReceipt(BuildContext context) {
    DateTime expenseDate;
    try {
      List<String> dateParts = date.split('/');
      expenseDate = DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
      );
    } catch (e) {
      expenseDate = DateTime.now();
    }

    final updatedReceipt = Receipt(
      id: widget.receipt?.id, // Retain ID if editing, generate new otherwise
      amount: double.tryParse(totalAmount.replaceAll('MYR ', '')) ?? 0,
      merchantName: _merchantNameController.text,
      date: expenseDate,
      taxAmount: double.tryParse(taxAmount.replaceAll('MYR ', '')) ?? 0,
      note: widget.receipt?.note ?? "Receipt saved from scan",
      imagePath: widget.imagePath,
    );

    final provider = Provider.of<ReceiptProvider>(context, listen: false);

    if (widget.receipt != null) {
      // Editing existing receipt
      provider.updateReceipt(updatedReceipt.id, updatedReceipt);
    } else {
      // Adding new receipt
      provider.addReceipt(updatedReceipt);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.receipt != null
            ? 'Receipt updated successfully!'
            : 'Receipt saved successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  PaymentMethod? selectedPaymentMethod;

  // Payment method with an empty list
  List<PaymentMethod> savedPaymentMethods = [];

  @override
  void initState() {
    super.initState();
    if (widget.receipt != null) {
      final receipt = widget.receipt!;
      storeName = receipt.merchantName;
      totalAmount = 'MYR ${receipt.amount.toStringAsFixed(2)}';
      taxAmount = 'MYR ${receipt.taxAmount.toStringAsFixed(2)}';
      date = _formatDate(receipt.date.toIso8601String());
      isLoading = false; // No need to process receipt for editing
    } else {
      storeName = '';
      totalAmount = 'MYR 0.00';
      taxAmount = 'MYR 0.00';
      date = 'DD/MM/YYYY';
      _processReceipt();
    }

    // Initialize the TextEditingController
    _merchantNameController = TextEditingController(text: storeName);
  }

  // Add this method to handle payment method selection
  void _selectPaymentMethod(PaymentMethod method) {
    setState(() {
      selectedPaymentMethod = method;
    });
    Navigator.pop(context);
  }

  // Add this method to handle adding new payment methods
  void _addNewPaymentMethod(String type) {
    Navigator.pop(context); // Close current bottom sheet

    PaymentMethod newMethod;
    switch (type) {
      case 'Cash':
        newMethod = PaymentMethod(
          name: 'Cash',
          subtitle: 'Cash',
          icon: Icons.money,
        );
        break;
      case 'E-Wallet':
        newMethod = PaymentMethod(
          name: 'E-Wallet',
          subtitle: 'Digital Payment',
          icon: Icons.account_balance_wallet,
        );
        break;
      case 'Debit Card':
        newMethod = PaymentMethod(
          name: 'Debit Card',
          subtitle: 'Bank Card',
          icon: Icons.credit_card,
        );
        break;
      default:
        return; // Return early if type doesn't match
    }

    setState(() {
      if (!savedPaymentMethods.any((method) => method.name == newMethod.name)) {
        savedPaymentMethods.add(newMethod);
      }
      selectedPaymentMethod = newMethod;
    });
  }

  // Add this method to build the payment method button
  void _showPaymentMethodSelector() {
    bool localIsEditingPaymentMethods = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 0.75,
              expand: false,
              builder: (_, controller) {
                return ListView(
                  controller: controller,
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Method',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              localIsEditingPaymentMethods =
                                  !localIsEditingPaymentMethods;
                            });
                          },
                          child: Text(
                            localIsEditingPaymentMethods ? 'Done' : 'Edit',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (savedPaymentMethods.isNotEmpty) ...[
                      const Text(
                        'Saved',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...savedPaymentMethods.map((method) => ListTile(
                            leading: Icon(
                              method.name == selectedPaymentMethod?.name
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: method.name == selectedPaymentMethod?.name
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            title: Text(method.name),
                            subtitle: Text(method.subtitle),
                            onTap: localIsEditingPaymentMethods
                                ? null
                                : () {
                                    setState(() {
                                      selectedPaymentMethod = method;
                                    });
                                    Navigator.pop(context);
                                  },
                            trailing: localIsEditingPaymentMethods
                                ? IconButton(
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    onPressed: () {
                                      setModalState(() {
                                        savedPaymentMethods.remove(method);
                                      });
                                      setState(() {
                                        if (selectedPaymentMethod == method) {
                                          selectedPaymentMethod = null;
                                        }
                                      });
                                    },
                                  )
                                : null,
                          )),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Custom',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 20),
                      ),
                      title: const Text('Add New Payment Method'),
                      onTap: () {
                        Navigator.pop(context);
                        _showAddPaymentMethodDialog();
                      },
                    ),
                    const SizedBox(height: 16),
                    // if (!localIsEditingPaymentMethods)
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: ElevatedButton.icon(
                    //     onPressed: () {
                    //       Navigator.pop(context);
                    //       _showAddPaymentMethodDialog();
                    //     },
                    //     icon: const Icon(Icons.add),
                    //     label: const Text('Add Payment Method'),
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: Colors.blue,
                    //       foregroundColor: Colors.white,
                    //       padding: const EdgeInsets.symmetric(vertical: 16),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(30),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddPaymentMethodDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildPaymentMethodOption(
                icon: Icons.money,
                title: 'Cash',
                onTap: () => _addNewPaymentMethod('Cash'),
              ),
              _buildPaymentMethodOption(
                icon: Icons.account_balance_wallet,
                title: 'E-Wallet',
                onTap: () => _addNewPaymentMethod('E-Wallet'),
              ),
              _buildPaymentMethodOption(
                icon: Icons.credit_card,
                title: 'Debit Card',
                onTap: () => _addNewPaymentMethod('Debit Card'),
              ),
            ],
          ),
        );
      },
    ).then((selectedMethod) {
      if (selectedMethod != null) {
        // Handle the new payment method
        setState(() {
          // Update UI with the new payment method
        });
      }
    });
  }

  Widget _buildPaymentMethodOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "DD/MM/YYYY";

    try {
      // Remove any time component if present
      dateStr = dateStr.split(' ')[0];

      // Try to parse the date string
      DateTime? parsedDate;

      // Handle common date formats
      if (dateStr.contains('/')) {
        // Already in DD/MM/YYYY format
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          int? day = int.tryParse(parts[0]);
          int? month = int.tryParse(parts[1]);
          int? year = int.tryParse(parts[2]);

          if (day != null && month != null && year != null) {
            parsedDate = DateTime(year, month, day);
          }
        }
      } else if (dateStr.contains('-')) {
        // Handle YYYY-MM-DD format
        parsedDate = DateTime.tryParse(dateStr);
      }

      if (parsedDate != null) {
        // Format as DD/MM/YYYY
        String day = parsedDate.day.toString().padLeft(2, '0');
        String month = parsedDate.month.toString().padLeft(2, '0');
        String year = parsedDate.year.toString();
        return "$day/$month/$year";
      }

      // If we can't parse it but it's already in correct format, return as is
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dateStr)) {
        return dateStr;
      }

      return "DD/MM/YYYY";
    } catch (e) {
      print('Error formatting date: $e');
      return "DD/MM/YYYY";
    }
  }

  Future<void> _processReceipt() async {
    try {
      print('Starting receipt processing...');
      final extractedData =
          await _extractionService.extractInformation(widget.scannedText);

      print('Extracted data received: $extractedData');

      if (extractedData != null) {
        if (mounted) {
          setState(() {
            // Extract and handle merchant name
            storeName =
                extractedData['merchant_name']?.toString() ?? 'Store Name';
            _merchantNameController.text = storeName;
            print('Set store name: $storeName');

            // Extract and handle total amount
            var rawAmount =
                extractedData['total_amount']?.toString() ?? 'MYR 50.50';
            rawAmount = rawAmount.toUpperCase().trim();
            rawAmount =
                rawAmount.replaceAll('RM', '').replaceAll('MYR', '').trim();
            totalAmount = 'MYR $rawAmount';
            print('Set total amount: $totalAmount');

            // Extract and handle tax amount
            var rawTax = extractedData['tax_amount']?.toString() ?? 'MYR 0.00';
            rawTax = rawTax.toUpperCase().trim();
            rawTax = rawTax.replaceAll('RM', '').replaceAll('MYR', '').trim();
            taxAmount = 'MYR $rawTax';
            print('Set tax amount: $taxAmount');

            // Extract and handle transaction date
            String rawDate =
                extractedData['transaction_date']?.toString() ?? '';
            date = _formatDate(rawDate);
            print('Set date: $date');

            // Any additional extracted data can be added here if needed.
          });
        }
      } else {
        print('No data was extracted');
      }
    } catch (e) {
      print('Error in _processReceipt: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          print('Loading state set to false');
        });
      }
    }
  }

  void _showAmountEditor(
      String currentAmount, String label, Function(String) onSave) {
    final controller = TextEditingController(
      text: currentAmount.replaceAll('MYR ', '').replaceAll('.', '').trim(),
    );

    void _updateText() {
      final rawText =
          controller.text.replaceAll(',', '').replaceAll('.', '').trim();
      if (rawText.isEmpty) {
        controller.value = TextEditingValue(
          text: "0.00",
          selection: TextSelection.collapsed(offset: 4),
        );
        return;
      }

      final value = int.tryParse(rawText) ?? 0;
      final formatted = (value / 100).toStringAsFixed(2);
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // Initialize controller value
    _updateText();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Currency label
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'MYR (RM)',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Amount input
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'MYR ',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.left,
                        autofocus: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none, // Removes borders
                          focusedBorder:
                              InputBorder.none, // Removes focused borders
                          enabledBorder:
                              InputBorder.none, // Removes enabled borders
                          contentPadding: EdgeInsets.zero, // Removes padding
                          fillColor: Colors
                              .transparent, // Makes background transparent
                          filled: false, // Ensures no background fill
                        ),
                        onChanged: (text) => _updateText(),
                      ),
                    ),
                  ],
                ),
              ),
              // Save button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      onSave('MYR ${controller.text}');
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'SAVE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDatePicker(Function(String) onDateSelected) async {
    // Try parsing the current 'date' string to set as the initial date
    DateTime initialDate;
    try {
      List<String> parts = date.split('/');
      initialDate = DateTime(
          int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (e) {
      // Fallback to today's date if there's an error parsing the date
      initialDate = DateTime.now();
    }

    // Show the calendar dialog
    List<DateTime?>? result = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
        selectedDayHighlightColor: Colors.blue,
        todayTextStyle: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
        selectedDayTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        closeDialogOnCancelTapped: true, // Don't close on "Cancel"
      ),
      dialogSize: const Size(350, 400),
      value: [initialDate], // Pass the initial date
      borderRadius: BorderRadius.circular(15),
    );

    // Handle the result
    if (result != null && result.isNotEmpty && result[0] != null) {
      DateTime selectedDate = result[0]!; // Get the selected date

      // Format the selected date as DD/MM/YYYY
      final formattedDate = "${selectedDate.day.toString().padLeft(2, '0')}/"
          "${selectedDate.month.toString().padLeft(2, '0')}/"
          "${selectedDate.year}";

      onDateSelected(formattedDate); // Pass the formatted date to the callback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _merchantNameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            onChanged: (value) {
                              setState(() {
                                storeName = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (widget.imagePath.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.file(File(widget.imagePath)),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildPaymentMethodButton(),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              _buildDetailRow('Tax', taxAmount),
                              _buildDetailRow('Total', totalAmount),
                              _buildDetailRow('Date', date),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.close,
                        label: 'Delete',
                        onPressed: () {
                          if (widget.receipt != null) {
                            final provider = Provider.of<ReceiptProvider>(
                                context,
                                listen: false);
                            provider.removeReceipt(
                                widget.receipt!.id); // Remove the receipt by ID
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Receipt deleted successfully!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          Navigator.pop(context); // Close the dialog
                        },
                        color:
                            Colors.red, // Optional: Change button color to red
                      ),
                      _buildActionButton(
                        icon: Icons.check_circle,
                        label: 'Save',
                        onPressed: () => _saveReceipt(context),
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return InkWell(
      onTap: () {
        if (label == 'Date') {
          _showDatePicker((selectedDate) {
            setState(() {
              date = selectedDate; // Update the date with the selected value
            });
          });
        } else if (label == 'Tax' || label == 'Total') {
          _showAmountEditor(value, label, (updatedValue) {
            setState(() {
              if (label == 'Tax') {
                taxAmount = updatedValue;
              } else if (label == 'Total') {
                totalAmount = updatedValue;
              }
            });
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed, // Change this line to make it nullable
    required Color color,
  }) {
    return TextButton(
      onPressed: onPressed, // TextButton accepts nullable callback
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton() {
    if (selectedPaymentMethod != null) {
      return OutlinedButton(
        onPressed: _showPaymentMethodSelector,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selectedPaymentMethod!.icon, color: Colors.black87),
            const SizedBox(width: 8),
            Text(
              selectedPaymentMethod!.name,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton(
      onPressed: _showPaymentMethodSelector,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('Payment Method', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}
