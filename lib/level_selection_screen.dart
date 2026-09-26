import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final String playerName;
  const LevelSelectionScreen({Key? key, required this.playerName})
      : super(key: key);

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  int _unlockedLevel = 1;
  bool _isLoading = true;

  late final String _randomQuote;

  final ScrollController _quoteScrollController = ScrollController();
  Timer? _quoteTimer;

  static const List<String> quotes = [
    "کمال انسان مثل آب در کوزه‌ی گلی است، جلوی نشت آن را نمی‌توان گرفت.",
    "کاروان ابدیت انسان هنوز در ازل است، پس کاروانت را انتخاب کن!",
    "مردم را دوست داشتن کمترین شباهت به خداست.",
    "خداوند جایی بهتر از کاروان کربلا برای تجلی ندارد.",
    "چنان‌چه انسانی به فاطمه‌ی زهرا سلام‌الله‌علیها متوجه شود از چنان نورانیتی او را برخوردار خواهد کرد که تاکنون تجربه نکرده باشد این امر تکرار شدنی می‌باشد.",
    "چنان‌چه نگاه به امام حسین علیه‌السلام انسان را متحول نکند حقیقت او هرگز به منصه‌ی ظهور نخواهد رسید.",
    "نگاه ساده به طبیعت نشانه‌ی غفلت است.",
    "امام حسین علیه‌السلام نمی‌تواند حتی لحظه‌ای هم از کشتی بودن برای نجات امت جدش فاصله بگیرد.",
    "فقط خدا را نگاه کن تا فقط تو را نگاه کند.",
    "هر چه انسان از خدا دورتر شود خدا به او نزدیک تر خواهد بود!"
  ];

  @override
  void initState() {
    super.initState();
    _randomQuote = quotes[Random().nextInt(quotes.length)];
    _loadProgress();
    _startQuoteAnimation();
  }

  void _startQuoteAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_quoteScrollController.hasClients) return;

      _quoteTimer?.cancel();
      _quoteTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (!_quoteScrollController.hasClients) return;

        final maxScroll = _quoteScrollController.position.maxScrollExtent;
        final currentScroll = _quoteScrollController.offset;

        if (maxScroll <= 0) return;

        if (currentScroll >= maxScroll) {
          _quoteScrollController.jumpTo(0);
        } else {
          _quoteScrollController.jumpTo(currentScroll + 1);
        }
      });
    });
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved =
          prefs.getInt('max_unlocked_level_${widget.playerName}') ?? 1;

      if (!mounted) return;
      setState(() {
        _unlockedLevel = saved.clamp(1, 10);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _unlockedLevel = 1;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _quoteScrollController.dispose();
    super.dispose();
  }

  void _openLevel(int level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          playerName: widget.playerName,
          level: level,
        ),
      ),
    ).then((_) {
      // بعد از برگشت از بازی، پیشرفت را دوباره می‌خوانیم تا اگر مرحله باز شد UI آپدیت شود
      _loadProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6E5),
      appBar: AppBar(
        title: Text(
          'قهرمان: ${widget.playerName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF8A00),
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8A00)),
            )
          : Column(
              children: [
                // کادر متن تصادفی متحرک در بالا
                Container(
                  margin: const EdgeInsets.all(12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFFFFD59E), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  height: 48,
                  child: ListView(
                    controller: _quoteScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      Center(
                        child: Text(
                          _randomQuote,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.25,
                    ),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      final level = index + 1;
                      final isUnlocked = level <= _unlockedLevel;

                      return InkWell(
                        onTap: isUnlocked ? () => _openLevel(level) : null,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? Colors.white
                                : Colors.white.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isUnlocked
                                  ? const Color(0xFFFFC77D)
                                  : const Color(0xFFFFE1B8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'مرحله $level',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isUnlocked
                                                  ? const Color(0xFF6B4226)
                                                  : const Color(0xFFBCAAA4),
                                            ),
                                          ),
                                          Icon(
                                            isUnlocked
                                                ? Icons.lock_open_rounded
                                                : Icons.lock_rounded,
                                            color: isUnlocked
                                                ? const Color(: isUnlocked
                                                ? const Color( const Color(0xFFBCAAA4),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Text(
                                        isUnlocked
                                            ? 'برای شروع لمس کنید'
                                            : 'قفل است',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isUnlocked
                                              ? const Color(0xFFFF8A00)
                                              : const Color(0xFFBCAAA4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isUnlocked)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
