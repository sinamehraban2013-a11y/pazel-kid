import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:saver_gallery/saver_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RewardService {
  static String getCardAssetPath(int level) {
    int cardIndex = ((level - 1) % 10) + 1;
    return 'assets/rewards/card_$cardIndex.png';
  }

  static Future<void> unlockReward(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reward_unlocked_$level', true);
  }

  static Future<bool> isRewardUnlocked(int level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('reward_unlocked_$level') ?? false;
  }

  static Future<bool> saveCardToGallery(String assetPath) async {
    try {
      final ByteData byteData = await rootBundle.load(assetPath);
      final Uint8List bytes = byteData.buffer.asUint8List();

      final result = await SaverGallery.saveImage(
        bytes,
        quality: 100,
        fileName: 'kik_card_${DateTime.now().millisecondsSinceEpoch}.png',
        androidRelativePath: 'Pictures/جورچین اندیشه',
        skipIfExists: false,
      );
      return result.isSuccess;
    } catch (_) {
      return false;
    }
  }
}
