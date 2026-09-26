import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 50, color: Color(0xFFFF8A00)),
                    const SizedBox(height: 12),
                    const Text(
                      'راهنما و قوانین بازی 🧩',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6B4226)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '۱. در هر مرحله، یک تصویر زیبا به تکه‌های پازل تقسیم می‌شود.\n'
                      '۲. هم‌زمان با شروع مرحله، یک موسیقی دلنشین پخش شده و تایمر معکوس فعال می‌شود.\n'
                      '۳. تکه‌های پازل را با کشیدن و رها کردن (Drag & Drop) در جای درست خود در صفحه بالا قرار دهید.\n'
                      '۴. با تکمیل پازل قبل از پایان زمان، مرحله بعد باز خواهد شد.\n'
                      '۵. هر زمان که بخواهید، می‌توانید از دکمه بازگشت برای رفتن به لیست مراحل استفاده کنید.',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 15, height: 1.8, color: Color(0xFF424242)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                        );
                      },
                      child: const Text('متوجه شدم، بزن بریم! 🚀', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
