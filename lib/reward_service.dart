import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RewardService {
  static const String _unlockedKey = 'unlocked_reward_cards';

  static String getCardAssetPath(int level) {
    final cardIndex = ((level - 1) % 10) + 1;
    return 'assets/rewards/card_$cardIndex.png';
  }

  static Future<void> unlockReward(int level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlocked = prefs.getStringList(_unlockedKey) ?? [];
      final levelStr = level.toString();
      if (!unlocked.contains(levelStr)) {
        unlocked.add(levelStr);
        await prefs.setStringList(_unlockedKey, unlocked);
      }
    } catch (_) {}
  }

  static Future<bool> isRewardUnlocked(int level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlocked = prefs.getStringList(_unlockedKey) ?? [];
      return unlocked.contains(level.toString());
    } catch (_) {
      return false;
    }
  }

  static Future<bool> saveCardToGallery(String assetPath) async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) return false;
      }

      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      await Gal.putImageBytes(
        bytes,
        name: 'hekmat_card_${DateTime.now().millisecondsSinceEpoch}',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
