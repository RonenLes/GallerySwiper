import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class GalleryProgress extends StatelessWidget {
  const GalleryProgress({
    required this.reviewed,
    required this.total,
    required this.progress,
    super.key,
  });

  final int reviewed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              total == 0 ? 'READY WHEN YOU ARE' : 'REVIEW PROGRESS',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                total == 0 ? '0 photos' : '$reviewed / $total',
                key: ValueKey(reviewed),
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        TweenAnimationBuilder<double>(
          tween: Tween(end: progress),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: 6,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: AppColors.track,
            color: AppColors.progress,
          ),
        ),
      ],
    );
  }
}
