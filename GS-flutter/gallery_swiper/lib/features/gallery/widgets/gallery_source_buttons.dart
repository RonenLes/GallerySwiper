import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class GallerySourceButtons extends StatelessWidget {
  const GallerySourceButtons({
    required this.isLoading,
    required this.onPick,
    required this.onScanAll,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onPick;
  final VoidCallback onScanAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SourceButton(
            label: 'Pick photos',
            icon: Icons.add_photo_alternate_outlined,
            color: AppColors.primary,
            onPressed: isLoading ? null : onPick,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SourceButton(
            label: 'Scan all',
            icon: Icons.photo_library_outlined,
            color: AppColors.surfaceStrong,
            loading: isLoading,
            onPressed: isLoading ? null : onScanAll,
          ),
        ),
      ],
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }
}
