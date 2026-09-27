import 'dart:async';
import 'package:flutter/material.dart';
import 'player_service.dart';
import 'package:puzzle_kids_game/level_selection_screen.dart';
import 'package:puzzle_kids_game/how_to_play_screen.dart' hide LevelSelectionScreen;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // ۳ ثانیه توقف برای نمایش اسپلش
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    String playerName = '';

    try {
      // استفاده از timeout برای جلوگیری از قفل شدن بی‌پایان
      final profile = await PlayerService.getProfile().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      playerName = profile?['name']?.toString().trim() ?? '';
    } catch (e) {
      debugPrint('Error loading player profile: $e');
      playerName = '';
    }

    if (!mounted) return;

    if (playerName.isNotEmpty) {
      // اگر قبلاً پروفایل داشت، مستقیم وارد انتخاب مراحل می‌شود
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LevelSelectionScreen(playerName: playerName),
        ),
      );
    } else {
      // اگر پروفایل نداشت یا خطا داد، به صفحه خوش‌آمدگویی و ساخت پروفایل هدایت می‌شود
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HowToPlayScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.extension_rounded,
                size: 90,
                color: Color(0xFFFF8A00),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'گروه محفل اُنس',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4226),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0B2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'تکه‌های کوچک؛ فکرهای بزرگ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE65100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
