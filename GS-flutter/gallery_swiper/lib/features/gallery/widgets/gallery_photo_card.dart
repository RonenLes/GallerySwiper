import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/theme/app_colors.dart';
import '../models/swipe_record.dart';
import 'asset_image.dart';

class GalleryPhotoCard extends StatelessWidget {
  const GalleryPhotoCard({
    required this.photo,
    required this.photoIndex,
    required this.hasPhotos,
    required this.keptCount,
    required this.deleteCount,
    required this.statusMessage,
    required this.onDecision,
    required this.onOpenPhoto,
    super.key,
  });

  final AssetEntity? photo;
  final int photoIndex;
  final bool hasPhotos;
  final int keptCount;
  final int deleteCount;
  final String? statusMessage;
  final ValueChanged<SwipeDecision> onDecision;
  final ValueChanged<AssetEntity> onOpenPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: .985, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: photo == null ? _buildEmptyState() : _buildPhoto(photo!),
              ),
              Positioned(
                top: 14,
                left: 16,
                right: photo == null ? 16 : 64,
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    reverseDuration: const Duration(milliseconds: 140),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, -.15),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: statusMessage == null
                        ? const SizedBox.shrink(key: ValueKey('no-status'))
                        : _StatusBanner(
                            key: ValueKey(statusMessage),
                            message: statusMessage!,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(AssetEntity asset) {
    return Dismissible(
      key: ValueKey('${asset.id}-$photoIndex'),
      direction: DismissDirection.horizontal,
      movementDuration: const Duration(milliseconds: 180),
      resizeDuration: null,
      dismissThresholds: const {
        DismissDirection.endToStart: .28,
        DismissDirection.startToEnd: .28,
      },
      onDismissed: (direction) => onDecision(
        direction == DismissDirection.endToStart
            ? SwipeDecision.delete
            : SwipeDecision.keep,
      ),
      background: const _SwipeBackground(
        color: AppColors.keepStrong,
        icon: Icons.favorite_rounded,
        label: 'KEEP',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const _SwipeBackground(
        color: AppColors.deleteStrong,
        icon: Icons.delete_outline_rounded,
        label: 'DELETE',
        alignment: Alignment.centerRight,
      ),
      child: GestureDetector(
        onTap: () => onOpenPhoto(asset),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GalleryAssetImage(asset: asset),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .25, .75, 1],
                  colors: [
                    Color(0x55000000),
                    Colors.transparent,
                    Colors.transparent,
                    Color(0x88000000),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: _PhotoOverlayButton(onPressed: () => onOpenPhoto(asset)),
            ),
            const Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe_rounded, size: 17),
                  SizedBox(width: 7),
                  Text(
                    'Swipe to decide',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      key: ValueKey(hasPhotos ? 'complete' : 'empty'),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: (hasPhotos ? AppColors.keep : AppColors.primary)
                    .withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasPhotos ? Icons.check_rounded : Icons.photo_outlined,
                color: hasPhotos ? AppColors.keep : AppColors.primaryLight,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasPhotos ? 'Review complete' : 'Your gallery, your call',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasPhotos
                  ? 'You kept $keptCount and marked $deleteCount for deletion.'
                  : 'Choose a selection or scan your library to start reviewing photos.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                height: 1.45,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xE6222632),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primaryLight,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoOverlayButton extends StatelessWidget {
  const _PhotoOverlayButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open photo',
      child: Material(
        color: const Color(0x99090B10),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onPressed,
          icon: const Icon(
            Icons.zoom_out_map_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 42),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
