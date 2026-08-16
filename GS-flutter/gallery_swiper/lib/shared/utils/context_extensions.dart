import 'package:flutter/material.dart';

extension GalleryContext on BuildContext {
  Future<void> showPhotoPermissionDialog({required VoidCallback openSettings}) {
    return showDialog<void>(
      context: this,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.photo_library_outlined),
        title: const Text('Photo access needed'),
        content: const Text(
          'Allow photo access in Settings to pick or scan your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
