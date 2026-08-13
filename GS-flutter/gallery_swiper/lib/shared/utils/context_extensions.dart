import 'package:flutter/material.dart';

extension MessageContext on BuildContext {
  void showMessage(String text) {
    final messenger = ScaffoldMessenger.of(this);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void showPermissionMessage({required VoidCallback openSettings}) {
    final messenger = ScaffoldMessenger.of(this);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Photo permission was denied.'),
          action: SnackBarAction(label: 'Settings', onPressed: openSettings),
        ),
      );
  }
}
