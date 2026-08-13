import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryAssetImage extends StatelessWidget {
  const GalleryAssetImage({
    required this.asset,
    this.fit = BoxFit.cover,
    super.key,
  });

  final AssetEntity asset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(
        const ThumbnailSize(1400, 1400),
        quality: 90,
      ),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Image.memory(bytes, fit: fit, gaplessPlayback: true);
      },
    );
  }
}
