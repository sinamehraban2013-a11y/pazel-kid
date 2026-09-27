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
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B4226),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        '۱. با شروع بازی یک موسیقی، نوا یا سخنرانی برای شما پخش می شود و زمان سنج که مدت آن را نمایش می دهد فعال می شود. شما تا پایان مدت پخش صدا می توانید پازل را تکمیل کنید و کارت هدیه مرحله را دریافت کنید.\n\n'
                        '۲. قطعات پازل را از پایین تصویر با انگشت کشیده و در جای مناسب آن در بالای تصویر قرار دهید.\n\n'
                        '۳. برای راهنمایی می توانید روی دکمه چشم در بالای صفحه کلیک کنید.\n\n'
                        '۴. برای دیدن قطعات در پایین صفحه، می توانید با دو انگشت صفحه زیرین را جابه جا کنید.',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.85,
                          color: Color(0xFF424242),
                        ),
                      ),
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
                      child: const Text(
                        'متوجه شدم، بزن بریم! 🚀',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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
