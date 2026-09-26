import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'splash_screen.dart';

void main() {
  // اطمینان از مقداردهی اولیه فلاتر
  WidgetsFlutterBinding.ensureInitialized();
  
  // قفل کردن چرخش صفحه روی حالت عمودی برای تجربه کاربری بهتر کودکان
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const PuzzleApp());
}

class PuzzleApp extends StatelessWidget {
  const PuzzleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'هنر و اندیشه',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFFFF8E7),
        fontFamily: 'Vazirmatn', // در صورت عدم وجود فونت، از فونت سیستم استفاده می‌شود
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF8A00),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
      ),
      // نقطه شروع برنامه همیشه با صفحه خوش‌آمدگویی ۳ ثانیه‌ای است
      home: const SplashScreen(),
    );
  }
}
