import 'dart:async';

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
import 'delete_review_page.dart';
import 'zoom_photo_page.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late final GalleryController _controller;
  final InstructionsService _instructionsService = InstructionsService();
  Timer? _statusTimer;
  String? _statusMessage;
  GallerySourceMode _sourceMode = GallerySourceMode.pickPhotos;

  @override
  void initState() {
    super.initState();
    _controller = GalleryController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInstructions());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
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
    final confirmed = await _confirmAction(
      title: 'Scan all photos?',
      message: 'Are you sure you want to scan all photos?',
    );
    if (!confirmed || !mounted) return;

    _controller.setLoading(true);
    try {
      final result = await _controller.mediaService.scanAllPhotos();
      if (!mounted) return;
      _handleLoadResult(result, emptyMessage: 'No photos found.');
    } finally {
      _controller.setLoading(false);
    }
  }

  Future<void> _runSelectedSource() async {
    switch (_sourceMode) {
      case GallerySourceMode.pickPhotos:
        await _pickPhotos();
      case GallerySourceMode.scanAll:
        await _scanAllPhotos();
      case GallerySourceMode.monthYear:
        await _chooseMonthYear();
      case GallerySourceMode.album:
        await _chooseAlbum();
    }
  }

  Future<void> _chooseMonthYear() async {
    final now = DateTime.now();
    var selectedYear = now.year;
    int? selectedMonth;
    final choice = await showDialog<({int year, int? month})>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Choose month and year'),
          content: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: selectedMonth,
                  decoration: const InputDecoration(labelText: 'Month'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any')),
                    for (var month = 1; month <= 12; month++)
                      DropdownMenuItem(
                        value: month,
                        child: Text(_monthNames[month - 1]),
                      ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedMonth = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: selectedYear,
                  decoration: const InputDecoration(labelText: 'Year'),
                  items: [
                    for (var year = now.year; year >= 1970; year--)
                      DropdownMenuItem(value: year, child: Text('$year')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedYear = value);
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, (
                year: selectedYear,
                month: selectedMonth,
              )),
              child: const Text('Load photos'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    _controller.setLoading(true);
    try {
      final result = await _controller.mediaService.scanPhotosByDate(
        year: choice.year,
        month: choice.month,
      );
      if (!mounted) return;
      _handleLoadResult(result, emptyMessage: 'No photos found for that date.');
    } finally {
      _controller.setLoading(false);
    }
  }

  Future<void> _chooseAlbum() async {
    _controller.setLoading(true);
    final List<AssetPathEntity>? albums;
    try {
      albums = await _controller.mediaService.getAlbums();
    } finally {
      _controller.setLoading(false);
    }
    if (!mounted) return;
    if (albums == null) {
      context.showPhotoPermissionDialog(
        openSettings: _controller.mediaService.openSettings,
      );
      return;
    }
    if (albums.isEmpty) {
      _showStatus('No albums found.');
      return;
    }
    final availableAlbums = albums;

    final album = await showModalBottomSheet<AssetPathEntity>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: availableAlbums.length,
          itemBuilder: (_, index) {
            final album = availableAlbums[index];
            return ListTile(
              leading: const Icon(Icons.photo_album_outlined),
              title: Text(album.name),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pop(sheetContext, album),
            );
          },
        ),
      ),
    );
    if (album == null || !mounted) return;

    _controller.setLoading(true);
    try {
      final result = await _controller.mediaService.scanAlbum(album);
      if (!mounted) return;
      _handleLoadResult(result, emptyMessage: 'No photos found in that album.');
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
        _showStatus(emptyMessage);
      case GalleryLoadStatus.permissionDenied:
        context.showPhotoPermissionDialog(
          openSettings: _controller.mediaService.openSettings,
        );
    }
  }

  void _decide(SwipeDecision decision) {
    _controller.decide(decision);
  }

  void _undo() {
    _controller.undo();
  }

  Future<void> _undoAll() async {
    final confirmed = await _confirmAction(
      title: 'Undo all actions?',
      message: 'Are you sure you want to undo all reviewed photos?',
    );
    if (!confirmed || !mounted) return;
    _controller.undoAll();
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showStatus(String message) {
    _statusTimer?.cancel();
    if (!mounted) return;
    setState(() => _statusMessage = message);
    _statusTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _statusMessage = null);
    });
  }

  Future<void> _deleteMarked() async {
    final action = await showDialog<_DeleteMarkedAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete marked photos?'),
        content: Text(
          'Are you sure you want to permanently delete '
          '${_controller.markedForDeletion.length} marked photo${_controller.markedForDeletion.length == 1 ? '' : 's'}?',
        ),
        actions: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () =>
                    Navigator.pop(dialogContext, _DeleteMarkedAction.review),
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('Review'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, _DeleteMarkedAction.no),
                child: const Text('No'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, _DeleteMarkedAction.yes),
                child: const Text('Yes'),
              ),
            ],
          ),
        ],
      ),
    );
    if (!mounted || action == null || action == _DeleteMarkedAction.no) return;
    if (action == _DeleteMarkedAction.review) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => DeleteReviewPage(controller: _controller),
        ),
      );
      return;
    }

    try {
      final deletedIds = await _controller.mediaService.deletePhotos(
        _controller.markedForDeletion,
      );
      if (!mounted) return;
      if (deletedIds.isEmpty) {
        _showStatus('Deletion canceled');
        return;
      }
      _controller.applyDeletedIds(deletedIds);
      _showStatus(
        '${deletedIds.length} photo${deletedIds.length == 1 ? '' : 's'} deleted.',
      );
    } catch (_) {
      _showStatus('Could not delete the selected photos');
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
                      mode: _sourceMode,
                      onRun: _runSelectedSource,
                      onModeChanged: (mode) {
                        setState(() => _sourceMode = mode);
                      },
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
                        statusMessage: _statusMessage,
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
                      onUndoAll: _undoAll,
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

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

enum _DeleteMarkedAction { no, review, yes }
