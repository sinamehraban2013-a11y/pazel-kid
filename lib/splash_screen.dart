import 'dart:async';
import 'package:flutter/material.dart';
import 'player_service.dart';
import 'how_to_play_screen.dart';
import 'level_selection_screen.dart';

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
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // getProfile ممکن است null برگرداند، پس باید null-safe خوانده شود
    final Map<String, dynamic>? profile = await PlayerService.getProfile();

    // استخراج امن نام
    final String playerName = profile?['name']?.toString().trim() ?? '';
    final booltrim() ?? '';
    final boolEmpty;

    if (!mounted) return;

    if (hasProfile) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LevelSelectionScreen(playerName: playerName),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HowToPlayScreen(),
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
          mainAxisAlignment: MainAxisInsets.all(20),
              [
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
              'هنر و اندیشه',
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
                'بازی برای پیشرفت',
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
