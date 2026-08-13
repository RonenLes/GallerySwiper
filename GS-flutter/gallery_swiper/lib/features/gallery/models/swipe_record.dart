import 'package:photo_manager/photo_manager.dart';

enum SwipeDecision { keep, delete }

class SwipeRecord {
  const SwipeRecord(this.asset, this.decision);

  final AssetEntity asset;
  final SwipeDecision decision;
}
