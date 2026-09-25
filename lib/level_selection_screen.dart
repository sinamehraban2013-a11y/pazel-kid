import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final String playerName;

  const LevelSelectionScreen({Key? key, required this.playerName}) : super(key: key);

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  int maxUnlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      maxUnlockedLevel = prefs.getInt('max_unlocked_level_${widget.playerName}') ?? 1;
    });
  }

  void _openLevel(int level) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          playerName: widget.playerName,
          initialLevel: level,
        ),
      ),
    );
    // پس از برگشت از بازی، مرحله‌های جدید بازشده را دوباره بخوان
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("انتخاب مرحله - ${widget.playerName}"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: 10,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.25,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (context, index) {
            final int level = index + 1;
            final int gridDim = level + 1; // مرحله ۱ میشه ۲×۲، مرحله ۲ میشه ۳×۳، مرحله ۹ میشه ۱۰×۱۰
            final int pieceCount = gridDim * gridDim;
            final bool isUnlocked = level <= maxUnlockedLevel;

            return InkWell(
              onTap: isUnlocked ? () => _openLevel(level) : null,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.deepPurple.shade600 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isUnlocked ? Icons.extension : Icons.lock,
                      color: isUnlocked ? Colors.amberAccent : Colors.grey.shade600,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "مرحله $level",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "پازل $gridDim×$gridDim ($pieceCount تکه)",
                      style: TextStyle(
                        fontSize: 13,
                        color: isUnlocked ? Colors.white70 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
