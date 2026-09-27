import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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

  final ScrollController _quoteScrollController = ScrollController();
  Timer? _marqueeTimer;

  static const List<String> quotes = [
    "کمال انسان مثل آب در کوزه‌ی گلی است، جلوی نشت آن را نمی‌توان گرفت.",
    "کاروان ابدیت انسان هنوز در ازل است، پس کاروانت را انتخاب کن!",
    "مردم را دوست داشتن کمترین شباهت به خداست.",
    "خداوند جایی بهتر از کاروان کربلا برای تجلی ندارد.",
    "نگاه ساده به طبیعت نشانه‌ی غفلت است.",
    "فقط خدا را نگاه کن تا فقط تو را نگاه کند.",
    "هر چه انسان از خدا دورتر شود خدا به او نزدیک تر خواهد بود!",
    "کاروانت را انتخاب کن و در مسیر عشق قدم بگذار."
  ];

  // اتصال جملات با دقیقا ۱۵ کاراکتر فاصله سفید
  String get _marqueeText => quotes.join(' ' * 15);

  void _startMarqueeScroll() {
    _marqueeTimer?.cancel();
    _marqueeTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_quoteScrollController.hasClients) return;
      final maxScroll = _quoteScrollController.position.maxScrollExtent;
      final currentScroll = _quoteScrollController.offset;

      if (maxScroll <= 0) return;

      if (currentScroll <= 0) {
        _quoteScrollController.jumpTo(maxScroll);
      } else {
        _quoteScrollController.jumpTo(currentScroll - 1);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_quoteScrollController.hasClients) {
        _quoteScrollController.jumpTo(
          _quoteScrollController.position.maxScrollExtent,
        );
      }
      _startMarqueeScroll();
    });
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved =
          prefs.getInt('max_unlocked_level_${widget.playerName}') ?? 1;

      if (!mounted) return;
      setState(() {
        _unlockedLevel = saved.clamp(1, 10).toInt();
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
    _marqueeTimer?.cancel();
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
      _loadProgress();
      if (_quoteScrollController.hasClients) {
        _quoteScrollController.jumpTo(
          _quoteScrollController.position.maxScrollExtent,
        );
      }
      _startMarqueeScroll();
    });
  }

  Future<void> _launchURL(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('امکان باز کردن پیوند وجود ندارد.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در باز کردن پیوند.')),
        );
      }
    }
  }

  // ۲. نمایش پنجره درباره ما با متن دقیق مدنظر شما
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(
          child: Text('درباره ما', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'این نرم‌افزار حاصل ایده‌پردازی و تلاش جوانان هنرمندی است که در پاسخ به ندای رهبر عزیزمان مخلصانه و خلاقانه جهاد تبیین را شروع کرده و امیدوارند با هدایت اهل فن و بزرگان بتوانند محصولاتی جذاب، فرهنگی و مفید را برای شما فراهم کنند.\n\n'
            'به دعای خیر شما و حمایت‌هایتان محتاجیم. با ما در شبکه‌های اجتماعی در ارتباط باشید.\n\n'
            'اللهم عجل لولیک الفرج',
            textAlign: TextAlign.justify,
            style: TextStyle(height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  // ۳. نمایش فرم ارتباط با ما و اتصال مستقیم به ایمیل
  void _showContactDialog() {
    final TextEditingController textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ارتباط با ما', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('نظرات، پیشنهادات و انتقادات خود را برای ما بنویسید:'),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 4,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                hintText: 'متن پیام شما...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () async {
              final message = textController.text.trim();
              if (message.isEmpty) return;

              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'm_khozani@yahoo.com',
                queryParameters: {
                  'subject': 'نظر کاربر در بازی پازل',
                  'body': message,
                },
              );

              Navigator.pop(ctx);
              await _launchURL(emailUri.toString());
            },
            child: const Text('ارسال'),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(String title, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () => _launchURL(url),
        child: Text(
          '$title $url',
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 13,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'منو',
            onSelected: (value) {
              if (value == 'about') {
                _showAboutDialog();
              } else if (value == 'contact') {
                _showContactDialog();
              } else {
                _launchURL(value);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'about',
                child: Text('درباره ما'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'https://eitaa.com/shiravi_ir',
                child: Text('کانال هزاران فکر عمیق استاد شیروی'),
              ),
              const PopupMenuItem(
                value: 'https://ble.ir/join/NGMyZGI5OT',
                child: Text('کانال پاسخ به پرسش‌های سخت'),
              ),
              const PopupMenuItem(
                value: 'https://eitaa.com/maghaleh_shiravi',
                child: Text('کانال مقالات علمی، آموزشی، فرهنگی'),
              ),
              const PopupMenuItem(
                value: 'https://eitaa.com/ketab_shiravi',
                child: Text('کانال کتب داستان، علمی و مذهبی'),
              ),
              const PopupMenuItem(
                value: 'https://www.shiravi.org',
                child: Text('سایت استاد دکتر شیروی'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'contact',
                child: Text('ارتباط با ما'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF8A00)),
            )
          : Column(
              children: [
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
                          _marqueeText,
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
                                                ? const Color(0xFFFF8A00)
                                                : const Color(0xFFBCAAA4),
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
