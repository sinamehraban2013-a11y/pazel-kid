import 'package:flutter/material.dart';
import 'player_service.dart';
import 'game_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  int _step = 1;

  void _next() async {
    if (_step == 1 && _nameController.text.trim().isNotEmpty) {
      setState(() => _step = 2);
    } else if (_step == 2 && _ageController.text.trim().isNotEmpty) {
      final name = _nameController.text.trim();
      final age = int.tryParse(_ageController.text.trim()) ?? 7;
      await PlayerService.saveProfile(name, age);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GameScreen(playerName: name, initialLevel: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(_step == 1 ? 'سلام قهرمان! اسمت چیه؟ 🎈' : 'چند سالته دوست من؟ 🎂',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6B4226))),
              const SizedBox(height: 24),
              TextField(
                controller: _step == 1 ? _nameController : _ageController,
                keyboardType: _step == 1 ? TextInputType.text : TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: _step == 1 ? 'نام قشنگت رو بنویس...' : 'مثلاً: 8',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
                onPressed: _next,
                child: Text(_step == 1 ? 'مرحله بعد ➡️' : 'ورود به دنیای بازی 🌟',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
