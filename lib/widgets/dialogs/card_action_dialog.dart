import 'package:flutter/material.dart';

class CardActionDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const CardActionDialog({
    Key? key,
    required this.onCancel,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Card Actions'),
      content: Text('What would you like to do with this card?'),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: onDelete,
          child: Text(
            'Delete',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
