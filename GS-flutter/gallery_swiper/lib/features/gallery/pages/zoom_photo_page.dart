import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../widgets/asset_image.dart';

class ZoomPhotoPage extends StatefulWidget {
  const ZoomPhotoPage({required this.asset, super.key});

  final AssetEntity asset;

  @override
  State<ZoomPhotoPage> createState() => _ZoomPhotoPageState();
}

class _ZoomPhotoPageState extends State<ZoomPhotoPage> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    if (_controller.value != Matrix4.identity()) {
      _resetZoom();
      return;
    }
    final position = _doubleTapDetails?.localPosition;
    if (position == null) return;
    const scale = 3.0;
    _controller.value = Matrix4.identity()
      ..translateByDouble(
        -position.dx * (scale - 1),
        -position.dy * (scale - 1),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _resetZoom() => _controller.value = Matrix4.identity();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Photo'),
        actions: [
          IconButton(
            tooltip: 'Reset zoom',
            onPressed: _resetZoom,
            icon: const Icon(Icons.fit_screen),
          ),
        ],
      ),
      body: GestureDetector(
        onDoubleTapDown: (details) => _doubleTapDetails = details,
        onDoubleTap: _toggleZoom,
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 1,
          maxScale: 6,
          child: SizedBox.expand(
            child: GalleryAssetImage(asset: widget.asset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
