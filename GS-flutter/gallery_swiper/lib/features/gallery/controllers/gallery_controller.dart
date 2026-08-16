import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/swipe_record.dart';
import '../services/gallery_media_service.dart';

class GalleryController extends ChangeNotifier {
  GalleryController({GalleryMediaService? mediaService})
    : mediaService = mediaService ?? GalleryMediaService();

  final GalleryMediaService mediaService;
  final List<AssetEntity> _photos = [];
  final List<AssetEntity> _markedForDeletion = [];
  final List<AssetEntity> _kept = [];
  final List<SwipeRecord> _history = [];

  int _currentIndex = 0;
  bool _loading = false;

  List<AssetEntity> get photos => List.unmodifiable(_photos);
  List<AssetEntity> get markedForDeletion =>
      List.unmodifiable(_markedForDeletion);
  int get keptCount => _kept.length;
  int get reviewedCount => _currentIndex.clamp(0, _photos.length);
  int get totalCount => _photos.length;
  bool get isLoading => _loading;
  bool get canUndo => _history.isNotEmpty;
  bool get hasPhotos => _photos.isNotEmpty;
  bool get isComplete => hasPhotos && currentPhoto == null;
  double get progress => hasPhotos ? reviewedCount / totalCount : 0;
  AssetEntity? get currentPhoto =>
      _currentIndex < _photos.length ? _photos[_currentIndex] : null;

  void setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }

  void loadPhotos(List<AssetEntity> photos) {
    _photos
      ..clear()
      ..addAll(photos);
    _markedForDeletion.clear();
    _kept.clear();
    _history.clear();
    _currentIndex = 0;
    notifyListeners();
  }

  void decide(SwipeDecision decision) {
    final photo = currentPhoto;
    if (photo == null) return;

    if (decision == SwipeDecision.delete) {
      _markedForDeletion.add(photo);
    } else {
      _kept.add(photo);
    }
    _history.add(SwipeRecord(photo, decision));
    _currentIndex++;
    notifyListeners();
  }

  bool undo() {
    if (_history.isEmpty) return false;
    final last = _history.removeLast();
    (last.decision == SwipeDecision.delete ? _markedForDeletion : _kept).remove(
      last.asset,
    );
    _currentIndex = (_currentIndex - 1).clamp(0, _photos.length);
    notifyListeners();
    return true;
  }

  bool undoAll() {
    if (_history.isEmpty) return false;
    _history.clear();
    _markedForDeletion.clear();
    _kept.clear();
    _currentIndex = 0;
    notifyListeners();
    return true;
  }

  bool removeFromDeletion(AssetEntity photo) {
    final markedIndex = _markedForDeletion.indexWhere(
      (marked) => marked.id == photo.id,
    );
    if (markedIndex == -1) return false;
    _markedForDeletion.removeAt(markedIndex);

    if (!_kept.any((kept) => kept.id == photo.id)) {
      _kept.add(photo);
    }
    final historyIndex = _history.lastIndexWhere(
      (record) => record.asset.id == photo.id,
    );
    if (historyIndex != -1) {
      _history[historyIndex] = SwipeRecord(photo, SwipeDecision.keep);
    }
    notifyListeners();
    return true;
  }

  void applyDeletedIds(List<String> deletedIds) {
    _photos.removeWhere((photo) => deletedIds.contains(photo.id));
    _markedForDeletion.removeWhere((photo) => deletedIds.contains(photo.id));
    _history.clear();
    _currentIndex = _currentIndex.clamp(0, _photos.length);
    notifyListeners();
  }
}
