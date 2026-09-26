import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({Key? key}) : super(key: key);

  Widget _buildStepItem({
    required String number,
    required String text,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFFFE0B2), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFFF8A00),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5D4037),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8E7),
        appBar: AppBar(
          title: const Text('راهنمای بازی'),
          backgroundColor: const Color(0xFFFF8A00),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    _buildStepItem(
                      number: '1',
                      text:
                          'با شروع بازی یک موسیقی، نوا یا سخنرانی برای شما پخش می شود و زمان سنج که مدت آن را نمایش می دهد فعال می شود. شما تا پایان مدت پخش صدا می توانید پازل را تکمیل کنید و کارت هدیه مرحله را دریافت کنید.',
                      icon: Icons.timer_rounded,
                    ),
                    _buildStepItem(
                      number: '2',
                      text:
                          'قطعات پازل را از پایین تصویر با انگشت کشیده و در جای مناسب آن در بالای تصویر قرار دهید.',
                      icon: Icons.touch_app_rounded,
                    ),
                    _buildStepItem(
                      number: '3',
                      text:
                          'برای راهنمایی می توانید روی دکمه چشم در بالای صفحه کلیک کنید.',
                      icon: Icons.visibility_rounded,
                    ),
                    _buildStepItem(
                      number: '4',
                      text:
                          'برای دیدن قطعات در پایین صفحه، می توانید با دو انگشت صفحه زیرین را جابه جا کنید.',
                      icon: Icons.pan_tool_rounded,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'متوجه شدم، بزن بریم رفیق',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
