import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RewardService {
  // کلید ذخیره‌سازی مراحل باز شده در SharedPreferences
  static const String _unlockedRewardsKey = 'unlocked_reward_cards';

  /// تعیین مسیر فایل تصویر کارت بر اساس شماره مرحله
  /// نگاشت چرخشی برای مراحل ۱ تا ۱۰ به card_1.png تا card_10.png
  static String getCardAssetPath(int level) {
    int cardIndex = ((level - 1) % 10) + 1;
    return 'assets/rewards/card_$cardIndex.png';
  }

  /// ثبت کارت جایزه در حافظه گوشی هنگام پیروزی
  static Future<void> unlockReward(int level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> unlockedList =
          prefs.getStringList(_unlockedRewardsKey) ?? [];

      String levelStr = level.toString();
      if (!unlockedList.contains(levelStr)) {
        unlockedList.add(levelStr);
        await prefs.setStringList(_unlockedRewardsKey, unlockedList);
      }
    } catch (e) {
      // خطا در ذخیره وضعیت کارت در حافظه محلی
    }
  }

  /// بررسی اینکه آیا کارت این مرحله قبلاً آزاد شده است یا خیر
  static Future<bool> isRewardUnlocked(int level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> unlockedList =
          prefs.getStringList(_unlockedRewardsKey) ?? [];
      return unlockedList.contains(level.toString());
    } catch (e) {
      return false;
    }
  }

  /// ذخیره تصویر کارت از درون برنامه (Asset) به گالری گوشی
  static Future<bool> saveCardToGallery(String assetPath) async {
    try {
      // خواندن بایت‌های تصویر از پوشه assets
      final ByteData byteData = await rootBundle.load(assetPath);
      final Uint8List uint8list = byteData.buffer.asUint8List();

      final String fileName = 'hekmat_card_${DateTime.now().millisecondsSinceEpoch}';

      // ذخیره مستقیم در گالری با مدیریت خودکار دسترسی‌ها
      final SaveResult result = await SaverGallery.saveImage(
        uint8list,
        quality: 100,
        fileName: fileName,
        androidRelativePath: "Pictures/PuzzleRewards",
        skipIfExists: false,
      );

      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }
}
