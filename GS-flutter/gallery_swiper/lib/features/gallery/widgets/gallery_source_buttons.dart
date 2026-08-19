import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum GallerySourceMode { pickPhotos, scanAll, monthYear, album }

extension GallerySourceModeDetails on GallerySourceMode {
  String get label => switch (this) {
    GallerySourceMode.pickPhotos => 'Pick photos',
    GallerySourceMode.scanAll => 'Scan all',
    GallerySourceMode.monthYear => 'Month / year',
    GallerySourceMode.album => 'Album',
  };

  IconData get icon => switch (this) {
    GallerySourceMode.pickPhotos => Icons.add_photo_alternate_outlined,
    GallerySourceMode.scanAll => Icons.photo_library_outlined,
    GallerySourceMode.monthYear => Icons.calendar_month_outlined,
    GallerySourceMode.album => Icons.photo_album_outlined,
  };
}

class GallerySourceButtons extends StatelessWidget {
  const GallerySourceButtons({
    required this.isLoading,
    required this.mode,
    required this.onRun,
    required this.onModeChanged,
    super.key,
  });

  final bool isLoading;
  final GallerySourceMode mode;
  final VoidCallback onRun;
  final ValueChanged<GallerySourceMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 48),
        const SizedBox(width: 8),
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 230),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: isLoading ? null : onRun,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(mode.icon, size: 20),
                label: Text(
                  mode.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<GallerySourceMode>(
          tooltip: 'Change scan option',
          enabled: !isLoading,
          initialValue: mode,
          onSelected: onModeChanged,
          icon: const Icon(Icons.tune_rounded),
          itemBuilder: (_) => GallerySourceMode.values
              .map(
                (option) => PopupMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      Icon(option.icon, size: 20),
                      const SizedBox(width: 12),
                      Text(option.label),
                      if (option == mode) ...[
                        const Spacer(),
                        const Icon(Icons.check_rounded, size: 18),
                      ],
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
