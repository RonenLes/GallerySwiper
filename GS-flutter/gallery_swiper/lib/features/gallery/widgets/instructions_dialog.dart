import 'package:flutter/material.dart';

class InstructionsDialog extends StatefulWidget {
  const InstructionsDialog({super.key});

  @override
  State<InstructionsDialog> createState() => _InstructionsDialogState();
}

class _InstructionsDialogState extends State<InstructionsDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How to use'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Swipe left to mark a photo for deletion.\n'
            'Swipe right to keep it.\n\n'
            'Nothing is deleted until you tap “Delete marked photos”.',
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Don't show again"),
            value: _dontShowAgain,
            onChanged: (value) {
              setState(() => _dontShowAgain = value ?? false);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _dontShowAgain),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
