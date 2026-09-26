import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'game_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final String playerName;

  const LevelSelectionScreen({Key? key, required this.playerName}) : super(key: key);

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  int _unlockedLevel = 1;
  final ScrollController _tickerController = ScrollController();
  Timer? _tickerTimer;

  static const List<String> _baseQuotes = [
    'تفکر عمیق کلید گشایش معماهای دشوار زندگی است.',
    'صبر و شکیبایی پیروزی در هر مرحله را نزدیک می‌کند.',
    'دقت و تمرکز کوچک‌ترین نشانه‌ها را آشکار می‌سازد.',
    'دانش و بینش نردبان رسیدن به قله‌های آرامش است.',
    'هر چالش فرصتی برای کشف هوش نهفته درون شماست.',
    'امید و پشتکار دلنشین‌ترین پاداش را می‌آفریند.',
    'نگاه ژرف به پیرامون حکمت‌های جهان را نشان می‌دهد.',
    'هر معما گامی به سوی روشنی، خرد و بالندگی است.',
  ];

  late String _scrollingText;

  @override
  void initState() {
    super.initState();
    _prepareQuotes();
    _loadProgress();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startContinuousScroll();
    });
  }

  void _prepareQuotes() {
    // ترکیب تصادفی در هر بار ورود برای تازگی محتوا
    final List<String> randomized = List<String>.from(_baseQuotes)..shuffle();
    final String separator = ' ' * 20;
    _scrollingText = randomized.join(separator) + separator;
  }

  void _startContinuousScroll() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 35), (_) {
      if (!_tickerController.hasClients) return;

      final double maxScroll = _tickerController.position.maxScrollExtent;
      final double currentOffset = _tickerController.offset;
      const double step = 1.4;

      if (currentOffset + step >= maxScroll) {
        _tickerController.jumpTo(0.0);
      } else {
        _tickerController.jumpTo(currentOffset + step);
      }
    });
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt('max_unlocked_level_${widget.playerName}') ?? 1;
    if (mounted) {
      setState(() {
        _unlockedLevel = level.clamp(1, 10);
      });
    }
  }

  Future<void> _launchExternalUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('امکان باز کردن نشانی اینترنتی نیست.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در باز کردن پیوند.')),
        );
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFFFF8A00)),
              SizedBox(width: 8),
              Text('درباره ما', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              'این نرم‌افزار حاصل ایده‌پردازی و تلاش جوانان هنرمندی است که در پاسخ به ندای رهبر عزیزمان مخلصانه و خلاقانه جهاد تبیین را شروع کرده و امیدوارند با هدایت اهل فن و بزرگان بتوانند محصولاتی جذاب، فرهنگی و مفید را برای شما فراهم کنند. به دعای خیر شما و حمایت‌هایتان محتاجیم. با ما در شبکه‌های اجتماعی در ارتباط باشید. اللهم عجل لولیک الفرج',
              textAlign: TextAlign.justify,
              style: TextStyle(height: 1.7, fontSize: 14, color: Color(0xFF4E342E)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('بستن', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('ارتباط با ما و ارسال نظر', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'دیدگاه و پیشنهادهای ارزشمند خود را بنویسید تا از طریق ایمیل برای ما ارسال گردد:',
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackCtrl,
                maxLines: 4,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'متن پیام یا نظر شما...',
                  filled: true,
                  fillColor: const Color(0xFFFFF8E7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFFCC80)),
                  ),
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
                final message = feedbackCtrl.text.trim();
                if (message.isEmpty) return;

                Navigator.pop(ctx);
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'm_khozani@yahoo.com',
                  queryParameters: {
                    'subject': 'پیام کاربر جورچین اندیشه: ${widget.playerName}',
                    'body': message,
                  },
                );

                try {
                  await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('برنامه ایمیل در دستگاه شما یافت نشد. لطفاً مستقیماً به m_khozani@yahoo.com پیام دهید.'),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                foregroundColor: Colors.white,
              ),
              child: const Text('ارسال ایمیل'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _tickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8E7),
        appBar: AppBar(
          title: Text('انتخاب مرحله - قهرمان: ${widget.playerName}'),
          backgroundColor: const Color(0xFFFF8A00),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'امکانات و ارتباطات',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (value) {
                switch (value) {
                  case 'about':
                    _showAboutDialog();
                    break;
                  case 'shiravi_eitaa':
                    _launchExternalUrl('https://eitaa.com/shiravi_ir');
                    break;
                  case 'ble_qa':
                    _launchExternalUrl('https://ble.ir/join/NGMyZGI5OT');
                    break;
                  case 'maghaleh_eitaa':
                    _launchExternalUrl('https://eitaa.com/maghaleh_shiravi');
                    break;
                  case 'ketab_eitaa':
                    _launchExternalUrl('https://eitaa.com/ketab_shiravi');
                    break;
                  case 'shiravi_web':
                    _launchExternalUrl('https://www.shiravi.org');
                    break;
                  case 'contact':
                    _showFeedbackDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'about',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFFF8A00), size: 20),
                      SizedBox(width: 10),
                      Text('درباره ما'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'shiravi_eitaa',
                  child: Row(
                    children: [
                      Icon(Icons.send_rounded, color: Colors.deepOrange, size: 20),
                      SizedBox(width: 10),
                      Text('کانال هزاران فکر عمیق استاد شیروی'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'ble_qa',
                  child: Row(
                    children: [
                      Icon(Icons.question_answer_rounded, color: Colors.teal, size: 20),
                      SizedBox(width: 10),
                      Text('کانال پاسخ به پرسش‌های سخت'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'maghaleh_eitaa',
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: Colors.indigo, size: 20),
                      SizedBox(width: 10),
                      Text('کانال مقالات علمی، آموزش، فرهنگی'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'ketab_eitaa',
                  child: Row(
                    children: [
                      Icon(Icons.book_rounded, color: Colors.green, size: 20),
                      SizedBox(width: 10),
                      Text('کانال کتب داستان، علمی و مذهبی'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'shiravi_web',
                  child: Row(
                    children: [
                      Icon(Icons.language_rounded, color: Colors.blue, size: 20),
                      SizedBox(width: 10),
                      Text('سایت استاد دکتر شیروی'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'contact',
                  child: Row(
                    children: [
                      Icon(Icons.mail_outline_rounded, color: Color(0xFFFF8A00), size: 20),
                      SizedBox(width: 10),
                      Text('ارتباط با ما'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // نوار متحرک جملات حکمت‌آمیز
            Container(
              height: 42,
              width: double.infinity,
              color: const Color(0xFFFFE0B2),
              alignment: Alignment.center,
              child: SingleChildScrollView(
                controller: _tickerController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    Text(
                      _scrollingText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFBF360C),
                      ),
                    ),
                    Text(
                      _scrollingText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFBF360C),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // گرید انتخاب مرحله‌ها
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  itemCount: 10,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final int level = index + 1;
                    final bool isUnlocked = level <= _unlockedLevel;

                    return InkWell(
                      onTap: isUnlocked
                          ? () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GameScreen(
                                    playerName: widget.playerName,
                                    level: level,
                                  ),
                                ),
                              );
                              _loadProgress();
                            }
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('این مرحله قفل است! ابتدا مرحله قبل را کامل کنید.'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isUnlocked ? Colors.white : const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isUnlocked ? const Color(0xFFFF8A00) : Colors.grey.shade400,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isUnlocked
                                  ? Colors.orange.withOpacity(0.18)
                                  : Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isUnlocked ? Icons.play_circle_fill_rounded : Icons.lock_rounded,
                              size: 42,
                              color: isUnlocked ? const Color(0xFFFF8A00) : Colors.grey.shade600,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'مرحله $level',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? const Color(0xFF6B4226) : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
