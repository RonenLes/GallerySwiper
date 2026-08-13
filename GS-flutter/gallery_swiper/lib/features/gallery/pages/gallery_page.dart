import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/context_extensions.dart';
import '../controllers/gallery_controller.dart';
import '../models/swipe_record.dart';
import '../services/gallery_media_service.dart';
import '../services/instructions_service.dart';
import '../widgets/gallery_action_controls.dart';
import '../widgets/gallery_header.dart';
import '../widgets/gallery_photo_card.dart';
import '../widgets/gallery_progress.dart';
import '../widgets/gallery_source_buttons.dart';
import '../widgets/instructions_dialog.dart';
import 'zoom_photo_page.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late final GalleryController _controller;
  final InstructionsService _instructionsService = InstructionsService();

  @override
  void initState() {
    super.initState();
    _controller = GalleryController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInstructions());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showInstructions({bool force = false}) async {
    if (force) await _instructionsService.enable();
    if (!await _instructionsService.shouldShow() || !mounted) return;

    final dontShowAgain = await showDialog<bool>(
      context: context,
      builder: (_) => const InstructionsDialog(),
    );
    if (dontShowAgain ?? false) await _instructionsService.hide();
  }

  Future<void> _pickPhotos() async {
    final result = await _controller.mediaService.pickPhotos(context);
    if (!mounted) return;
    _handleLoadResult(result, emptyMessage: 'No photos selected.');
  }

  Future<void> _scanAllPhotos() async {
    _controller.setLoading(true);
    try {
      final result = await _controller.mediaService.scanAllPhotos();
      if (!mounted) return;
      _handleLoadResult(result, emptyMessage: 'No photos found.');
    } finally {
      _controller.setLoading(false);
    }
  }

  void _handleLoadResult(
    GalleryLoadResult result, {
    required String emptyMessage,
  }) {
    switch (result.status) {
      case GalleryLoadStatus.loaded:
        _controller.loadPhotos(result.photos);
      case GalleryLoadStatus.empty:
        context.showMessage(emptyMessage);
      case GalleryLoadStatus.permissionDenied:
        context.showPermissionMessage(
          openSettings: _controller.mediaService.openSettings,
        );
    }
  }

  void _decide(SwipeDecision decision) {
    final message = _controller.decide(decision);
    if (message != null) context.showMessage(message);
  }

  void _undo() {
    if (_controller.undo()) context.showMessage('Undid last action');
  }

  Future<void> _deleteMarked() async {
    try {
      final deletedIds = await _controller.mediaService.deletePhotos(
        _controller.markedForDeletion,
      );
      if (!mounted) return;
      if (deletedIds.isEmpty) {
        context.showMessage('Deletion canceled.');
        return;
      }
      _controller.applyDeletedIds(deletedIds);
      context.showMessage(
        '${deletedIds.length} photo${deletedIds.length == 1 ? '' : 's'} deleted.',
      );
    } catch (_) {
      if (mounted) context.showMessage('Could not delete the selected photos.');
    }
  }

  Future<void> _openPhoto(AssetEntity photo) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => ZoomPhotoPage(asset: photo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundTop, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GalleryHeader(onHelp: () => _showInstructions(force: true)),
                    const SizedBox(height: 20),
                    GallerySourceButtons(
                      isLoading: _controller.isLoading,
                      onPick: _pickPhotos,
                      onScanAll: _scanAllPhotos,
                    ),
                    const SizedBox(height: 18),
                    GalleryProgress(
                      reviewed: _controller.reviewedCount,
                      total: _controller.totalCount,
                      progress: _controller.progress,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GalleryPhotoCard(
                        photo: _controller.currentPhoto,
                        photoIndex: _controller.reviewedCount,
                        hasPhotos: _controller.hasPhotos,
                        keptCount: _controller.keptCount,
                        deleteCount: _controller.markedForDeletion.length,
                        onDecision: _decide,
                        onOpenPhoto: _openPhoto,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GalleryActionControls(
                      canDecide: _controller.currentPhoto != null,
                      canUndo: _controller.canUndo,
                      deleteCount: _controller.markedForDeletion.length,
                      onUndo: _undo,
                      onDeleteDecision: () => _decide(SwipeDecision.delete),
                      onKeepDecision: () => _decide(SwipeDecision.keep),
                      onDeleteMarked: _deleteMarked,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
