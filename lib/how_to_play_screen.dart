import 'package:flutter/material.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E5),
      appBar: AppBar(
        title: const Text('راهنمای بازی', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF8A00),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '۱. با شروع بازی یک موسیقی، نوا یا سخنرانی برای شما پخش می شود و زمان سنج که مدت آن را نمایش می دهد فعال می شود. شما تا پایان مدت پخش صدا می توانید پازل را تکمیل کنید و کارت هدیه مرحله را دریافت کنید.\n\n'
                  '۲. قطعات پازل را از پایین تصویر با انگشت کشیده و در جای مناسب آن در بالای تصویر قرار دهید.\n\n'
                  '۳. برای راهنمایی می توانید روی دکمه چشم در بالای صفحه کلیک کنید.\n\n'
                  '۴. برای دیدن قطعات در پایین صفحه، می توانید با دو انگشت صفحه زیرین را جابه جا کنید.',
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 16, height: 2.0, color: Color(0xFF5D4037)),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('متوجه شدم، بزن بریم!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
