import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/gallery_controller.dart';
import '../widgets/asset_image.dart';
import 'zoom_photo_page.dart';

class DeleteReviewPage extends StatelessWidget {
  const DeleteReviewPage({required this.controller, super.key});

  final GalleryController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Review marked photos'),
        backgroundColor: AppColors.background,
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final photos = controller.markedForDeletion;
          if (photos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 52),
                  SizedBox(height: 12),
                  Text('No photos marked for deletion'),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => ZoomPhotoPage(
                        asset: photo,
                        onUndoDelete: () =>
                            controller.removeFromDeletion(photo),
                      ),
                    ),
                  ),
                  child: GalleryAssetImage(asset: photo),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
