import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class GalleryHeader extends StatelessWidget {
  const GalleryHeader({required this.onHelp, super.key});

  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D6C63FF),
                blurRadius: 18,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome_mosaic, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GallerySwiper',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'A cleaner camera roll, one swipe at a time',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'How to use',
          onPressed: onHelp,
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
    );
  }
}
