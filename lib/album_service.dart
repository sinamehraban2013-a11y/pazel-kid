import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AlbumService {
  static const String _key = 'unlocked_album_cards';

  // دریافت لیست تصاویر حل‌شده
  static Future<List<String>> getUnlockedCards() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    return List<String>.from(jsonDecode(data));
  }

  // اضافه کردن تصویر حل‌شده به دفترچه افتخارات
  static Future<void> saveToAlbum(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = await getUnlockedCards();
    if (!list.contains(imagePath)) {
      list.add(imagePath);
      await prefs.setString(_key, jsonEncode(list));
    }
  }
}
