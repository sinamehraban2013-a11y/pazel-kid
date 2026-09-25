import 'package:shared_preferences/shared_preferences.dart';

class PlayerService {
  static const _keyName = 'player_name';
  static const _keyAge = 'player_age';
  static const _keyLevel = 'current_level';

  static Future<void> saveProfile(String name, int age) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setInt(_keyAge, age);
    if (!prefs.containsKey(_keyLevel)) {
      await prefs.setInt(_keyLevel, 1);
    }
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName);
    final age = prefs.getInt(_keyAge);
    final level = prefs.getInt(_keyLevel) ?? 1;

    if (name == null || age == null) return null;
    return {'name': name, 'age': age, 'level': level};
  }

  static Future<void> updateLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLevel, level);
  }
}
