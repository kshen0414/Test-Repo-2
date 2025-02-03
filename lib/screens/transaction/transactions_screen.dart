import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/receipt_provider.dart';
// import '../../widgets/dialogs/edit_receipt_dialog.dart';
import '../../widgets/dialogs/scan_result_dialog.dart';

class TransactionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final receiptProvider = Provider.of<ReceiptProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts'),
        centerTitle: true,
      ),
      body: receiptProvider.receipts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/Receipt.svg',
                      height: 320,
                      width: 320,
                      // colorFilter: ColorFilter.mode(
                      //   Colors.grey[400]!,
                      //   BlendMode.srcIn,
                      // ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'No Receipts Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start by scanning your first receipt',
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
            )
          : ListView.separated(
              itemCount: receiptProvider.receipts.length,
              itemBuilder: (context, index) {
                final receipt = receiptProvider.receipts[index];
                return ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: Text(
                    receipt.merchantName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Date: ${receipt.date.toLocal().toIso8601String().split('T').first}\n'
                    'Tax: RM ${receipt.taxAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  trailing: Text(
                    '-RM ${receipt.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade600,
                    ),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => ScanResultDialog(
                        imagePath: receipt.imagePath ?? '',
                        scannedText: '',
                        receipt: receipt,
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (context, index) => const Divider(),
            ),
    );
  }
}