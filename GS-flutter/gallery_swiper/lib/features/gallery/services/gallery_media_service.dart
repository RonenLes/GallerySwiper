import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

enum GalleryLoadStatus { loaded, empty, permissionDenied }

class GalleryLoadResult {
  const GalleryLoadResult(this.status, [this.photos = const []]);

  final GalleryLoadStatus status;
  final List<AssetEntity> photos;
}

class GalleryMediaService {
  Future<bool> requestAccess() async {
    final permission = await PhotoManager.requestPermissionExtend();
    return permission.hasAccess;
  }

  Future<GalleryLoadResult> pickPhotos(BuildContext context) async {
    if (!await requestAccess()) {
      return const GalleryLoadResult(GalleryLoadStatus.permissionDenied);
    }
    if (!context.mounted) {
      return const GalleryLoadResult(GalleryLoadStatus.empty);
    }

    final selected = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        maxAssets: 100,
        requestType: RequestType.image,
      ),
    );
    if (selected == null || selected.isEmpty) {
      return const GalleryLoadResult(GalleryLoadStatus.empty);
    }
    return GalleryLoadResult(GalleryLoadStatus.loaded, selected);
  }

  Future<GalleryLoadResult> scanAllPhotos() async {
    if (!await requestAccess()) {
      return const GalleryLoadResult(GalleryLoadStatus.permissionDenied);
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) {
      return const GalleryLoadResult(GalleryLoadStatus.empty);
    }

    final album = albums.first;
    final photos = await album.getAssetListPaged(
      page: 0,
      size: await album.assetCountAsync,
    );
    return GalleryLoadResult(
      photos.isEmpty ? GalleryLoadStatus.empty : GalleryLoadStatus.loaded,
      photos,
    );
  }

  Future<GalleryLoadResult> scanPhotosByDate({
    required int year,
    int? month,
  }) async {
    final all = await scanAllPhotos();
    if (all.status != GalleryLoadStatus.loaded) return all;

    final photos = <AssetEntity>[];
    for (final photo in all.photos) {
      final date = photo.createDateTime;
      if (date.year == year && (month == null || date.month == month)) {
        photos.add(photo);
      }
    }
    return GalleryLoadResult(
      photos.isEmpty ? GalleryLoadStatus.empty : GalleryLoadStatus.loaded,
      photos,
    );
  }

  Future<List<AssetPathEntity>?> getAlbums() async {
    if (!await requestAccess()) return null;
    return PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: false,
    );
  }

  Future<GalleryLoadResult> scanAlbum(AssetPathEntity album) async {
    final photos = await album.getAssetListPaged(
      page: 0,
      size: await album.assetCountAsync,
    );
    return GalleryLoadResult(
      photos.isEmpty ? GalleryLoadStatus.empty : GalleryLoadStatus.loaded,
      photos,
    );
  }

  Future<List<String>> deletePhotos(List<AssetEntity> photos) {
    return PhotoManager.editor.deleteWithIds(
      photos.map((photo) => photo.id).toList(growable: false),
    );
  }

  void openSettings() => PhotoManager.openSetting();
}
