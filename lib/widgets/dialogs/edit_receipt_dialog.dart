import 'package:flutter/material.dart';
import '../../models/receipt.dart';


class EditReceiptDialog extends StatefulWidget {
  final Receipt receipt;
  final Function(Receipt) onSave;

  const EditReceiptDialog({
    Key? key,
    required this.receipt,
    required this.onSave,
  }) : super(key: key);

  @override
  _EditReceiptDialogState createState() => _EditReceiptDialogState();
}

class _EditReceiptDialogState extends State<EditReceiptDialog> {
  late TextEditingController _merchantNameController;
  late TextEditingController _amountController;
  late TextEditingController _taxController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _merchantNameController =
        TextEditingController(text: widget.receipt.merchantName);
    _amountController =
        TextEditingController(text: widget.receipt.amount.toStringAsFixed(2));
    _taxController =
        TextEditingController(text: widget.receipt.taxAmount.toStringAsFixed(2));
    _selectedDate = widget.receipt.date;
  }

  @override
  void dispose() {
    _merchantNameController.dispose();
    _amountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

void _saveChanges() {
  final updatedReceipt = widget.receipt.copyWith(
    merchantName: _merchantNameController.text,
    amount: double.tryParse(_amountController.text) ?? widget.receipt.amount,
    taxAmount: double.tryParse(_taxController.text) ?? widget.receipt.taxAmount,
    date: _selectedDate,
  );

  widget.onSave(updatedReceipt);
  Navigator.pop(context);
}


  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Receipt'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _merchantNameController,
              decoration: const InputDecoration(labelText: 'Merchant Name'),
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total Amount (RM)'),
            ),
            TextField(
              controller: _taxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tax Amount (RM)'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Date: '),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                    '${_selectedDate.toLocal()}'.split(' ')[0],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
