
import 'package:flutter/material.dart';
import 'player_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'level_selection_screen.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({Key? key}) : super(key: key);

  // مرحله ۱: دریافت نام
  void _showNameDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'نام شما',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4226)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'لطفاً نام قشنگت رو بنویس:',
                style: TextStyle(fontSize: 14, color: Color(0xFF5D4037)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'مثلاً: علی',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF8A00), width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.pop(ctx);
                    _showAgeDialog(context, name);
                  }
                },
                child: const Text('مرحله بعد (ثبت سن)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // مرحله ۲: دریافت سن و ورود قطعی به صفحه مراحل
  void _showAgeDialog(BuildContext context, String playerName) {
    final TextEditingController ageController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'سن شما',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4226)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'آفرین $playerName عزیز! حالا بگو چند سالته؟',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF5D4037)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'مثلاً: ۹',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF8A00), width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
onPressed: () async {
  final rawAge = ageController.text.trim();
  if (rawAge.isEmpty) return;

  // تبدیل ارقام فارسی و عربی به انگلیسی
  final normalizedAge = rawAge
      .replaceAllMapped(
        RegExp(r'[۰-۹]'),
        (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x06F0 + 0x30),
      )
      .replaceAllMapped(
        RegExp(r'[٠-٩]'),
        (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0x0660 + 0x30),
      );

  final age = int.tryParse(normalizedAge);
  if (age == null) return;

  // ذخیره استاندارد و صحیح از طریق سرویس بازیکن
  await PlayerService.saveProfile(playerName, age);

  if (context.mounted) {
    Navigator.pop(ctx);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LevelSelectionScreen(playerName: playerName),
      ),
    );
  }
},
                child: const Text('شروع بازی!', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E5),
      appBar: AppBar(
        title: const Text('راهنمای بازی', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF8A00),
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFD59E), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const SingleChildScrollView(
                    child: Text(
                      '۱. با شروع بازی یک موسیقی، نوا یا سخنرانی برای شما پخش می شود و زمان سنج که مدت آن را نمایش می دهد فعال می شود. شما تا پایان مدت پخش صدا می توانید پازل را تکمیل کنید و کارت هدیه مرحله را دریافت کنید.\n\n'
                      '۲. قطعات پازل را از پایین تصویر با انگشت کشیده و در جای مناسب آن در بالای تصویر قرار دهید.\n\n'
                      '۳. برای راهنمایی می توانید روی دکمه چشم در بالای صفحه کلیک کنید.\n\n'
                      '۴. برای دیدن قطعات در پایین صفحه، می توانید با دو انگشت صفحه زیرین را جابه جا کنید.',
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.9,
                        color: Color(0xFF5D4037),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A00),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _showNameDialog(context),
                  child: const Text(
                    'متوجه شدم، بزن بریم!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
