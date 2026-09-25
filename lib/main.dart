import 'package:flutter/material.dart';
import 'player_service.dart';
import 'onboarding_screen.dart';
import 'game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final profile = await PlayerService.getProfile();
  runApp(PuzzleApp(profile: profile));
}

class PuzzleApp extends StatelessWidget {
  final Map<String, dynamic>? profile;
  const PuzzleApp({Key? key, this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بازی پازل شاد',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Vazirmatn'), // یا فونت دلخواه کودکانه
      home: profile == null
          ? const OnboardingScreen()
          : GameScreen(playerName: profile!['name'], initialLevel: profile!['level']),
    );
  }
}
