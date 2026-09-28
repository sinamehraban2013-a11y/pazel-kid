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

   Future<bool> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('خروج از برنامه؟'),
          content: const Text('آیا مطمئن هستید که می‌خواهید خارج شوید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ادامه بازی'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('خروج'),
            ),
          ],
        ),
      ),
    );

    return shouldExit ?? false;
  } 
  // متد هوشمند برای باز کردن مستقیم در اپلیکیشن ایتا یا هدایت به مرورگر
  Future<void> _openEitaaChannel({
    required String webUrl,
    required String appUrl,
  }) async {
    final Uri appUri = Uri.parse(appUrl);
    final Uri webUri = Uri.parse(webUrl);

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(
          appUri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        return;
      }
    } catch (_) {}

    await launchUrl(
      webUri,
      mode: LaunchMode.externalApplication,
    );
  }

  // دیالوگ راهنمای بازی
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'راهنمای بازی',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4226)),
          ),
          content: const SingleChildScrollView(
            child: Text(
              '۱. با شروع بازی یک موسیقی، نوا یا سخنرانی برای شما پخش می شود و زمان سنج که مدت آن را نمایش می دهد فعال می شود. شما تا پایان مدت پخش صدا می توانید پازل را تکمیل کنید و کارت هدیه مرحله را دریافت کنید.\n'
              '۲. قطعات پازل را از پایین تصویر با انگشت کشیده و در جای مناسب آن در بالای تصویر قرار دهید.\n'
              '۳. برای راهنمایی می توانید روی دکمه چشم در بالای صفحه کلیک کنید.\n'
              '۴. برای دیدن قطعات در پایین صفحه، می توانید با دو انگشت صفحه زیرین را جابه جا کنید.\n'
              '۵. برای خروج از بازی، دکمه بازگشت گوشی را لمس کنید تا پیام تأیید خروج نمایش داده شود.',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 15, height: 1.8, color: Color(0xFF5D4037)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('بستن', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // نمایش پنجره درباره ما
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Center(
            child: Text('درباره ما', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4226))),
          ),
          content: const SingleChildScrollView(
            child: Text(
              'این نرم‌افزار حاصل ایده‌پردازی و تلاش جوانان هنرمندی است که در پاسخ به ندای رهبر عزیزمان مخلصانه و خلاقانه جهاد تبیین را شروع کرده و امیدوارند با هدایت اهل فن و بزرگان بتوانند محصولاتی جذاب، فرهنگی و مفید را برای شما فراهم کنند.\n\n'
              'به دعای خیر شما و حمایت‌هایتان محتاجیم. با ما در شبکه‌های اجتماعی در ارتباط باشید.\n\n'
              'اللهم عجل لولیک الفرج',
              textAlign: TextAlign.justify,
              style: TextStyle(height: 1.7, color: Color(0xFF5D4037)),
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

  // نمایش فرم ارتباط با ما و اتصال مستقیم به ایمیل
  void _showContactDialog() {
    final TextEditingController textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('ارتباط با ما', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
              ),
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
      ),
    );
  }

  // تابع ساخت کارت‌های زیبای منو با طراحی اختصاصی
  Widget _buildMenuSheetItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF6B4226),
    Color iconBgColor = const Color(0xFFF5EBE1),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEADBCE), width: 1),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: iconBgColor,
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF4A2810),
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF8D6E63),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 14,
                  color: Color(0xFFBCAAA4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // نمایش منوی کشویی پایین
  void _showMoreMenuSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFFF7ED), // پس‌زمینه کرم گرم و چشم‌نواز
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // دستگیره بالای منو
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4226).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  _buildMenuSheetItem(
                    icon: Icons.info_outline_rounded,
                    title: 'درباره ما',
                    subtitle: 'با ما بیشتر آشنا شوید',
                    iconColor: const Color(0xFF6B4226),
                    iconBgColor: const Color(0xFFF3E7DC),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showAboutDialog();
                    },
                  ),
                  _buildMenuSheetItem(
                    icon: Icons.send_rounded,
                    title: 'کانال هزاران فکر عمیق استاد دکترشیروی',
                    subtitle: 'کلیک کنید، سپس روی دکمه پیوستن بزنید',
                    iconColor: const Color(0xFFFF8A00),
                    iconBgColor: const Color(0xFFFFF0DC),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openEitaaChannel(
                        webUrl: 'https://eitaa.com/shiravi_ir',
                        appUrl: 'eitaa://shiravi_ir',
                      );
                    },
                  ),
                  _buildMenuSheetItem(
                    icon: Icons.question_answer_rounded,
                    title: 'گروه پاسخ به پرسش‌های سخت استاد دکتر شیروی',
                    subtitle: 'کلیک کنید، سپس عضو گروه شوید',
                    iconColor: const Color(0xFF00897B),
                    iconBgColor: const Color(0xFFE0F2F1),
                    onTap: () {
                      Navigator.pop(ctx);
                      _launchURL('https://ble.ir/join/NGMyZGI5OT');
                    },
                  ),
                  _buildMenuSheetItem(
                    icon: Icons.menu_book_rounded,
                    title: 'کانال بروزترین مقالات فرهنگی، آموزشی',
                    subtitle: 'کلیک کنید، سپس روی دکمه پیوستن بزنید',
                    iconColor: const Color(0xFF2E7D32),
                    iconBgColor: const Color(0xFFE8F5E9),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openEitaaChannel(
                        webUrl: 'https://eitaa.com/maghaleh_shiravi',
                        appUrl: 'eitaa://maghaleh_shiravi',
                      );
                    },
                  ),
                  _buildMenuSheetItem(
                    icon: Icons.auto_stories_rounded,
                    title: 'کانال جدیدترین کتب تالیفی گروه محفل انس',
                    subtitle: 'کلیک کنید، سپس روی دکمه پیوستن بزنید',
                    iconColor: const Color(0xFF8E24AA),
                    iconBgColor: const Color(0xFFF3E5F5),
                    onTap: () {
                      Navigator.pop(ctx);
                      _openEitaaChannel(
                        webUrl: 'https://eitaa.com/ketab_shiravi',
                        appUrl: 'eitaa://ketab_shiravi',
                      );
                    },
                  ),
                  _buildMenuSheetItem(
                    icon: Icons.language_rounded,
                    title: 'سایت رسمی استاد دکتر شیروی',
                    subtitle: 'به دنیایی از هزاران شگفتی وارد شوید',
                    iconColor: const Color(0xFF0288D1),
                    iconBgColor: const Color(0xFFE1F5FE),
                    onTap: () {
                      Navigator.pop(ctx);
                      _launchURL('https://www.shiravi.org');
                    },
                  ),
                  _buildMenuSheetItem(
                    icon: Icons.mail_outline_rounded,
                    title: 'ارتباط با ما',
                    subtitle: 'ارسال پیشنهادات و نظرات از طریق ایمیل',
                    iconColor: const Color(0xFFE65100),
                    iconBgColor: const Color(0xFFFFE0B2),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showContactDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
      backgroundColor: const Color(0xFFFFF6E5),
      appBar: AppBar(
        title: Text(
          'قهرمان: ${widget.playerName}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6B4226),
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'راهنمای بازی',
            onPressed: _showHelpDialog,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'منو',
            onPressed: _showMoreMenuSheet,
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
                                  ? const Color(0xFF6B4226)
                                  : const Color(0xFFFF8F00),
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
      ),
    );
  }
}
