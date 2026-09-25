import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'asset_manager.dart';
import 'puzzle_helper.dart';

class GameScreen extends StatefulWidget {
  final String playerName;
  final int initialLevel;

  const GameScreen({
    Key? key,
    required this.playerName,
    this.initialLevel = 1,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late int currentLevel;
  int rows = 2;
  int cols = 2;
  int totalPieces = 4;

  bool isLoading = true;
  bool hasError = false;
  String errorMessage = "";
  String loadingStatus = "در حال اتصال و آماده‌سازی...";
  double? downloadProgress;
  int downloadedBytes = 0;

  Uint8List? currentImageBytes;
  String? currentAudioPath;

  List<PuzzlePieceData> remainingPieces = [];
  List<PuzzlePieceData?> placedPieces = [];

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _playerCompleteSubscription;
  bool _isLevelComplete = false;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    // فعال‌سازی روشن ماندن دائمی صفحه در زمان باز بودن بازی
    WakelockPlus.enable();

    currentLevel = widget.initialLevel;
    _setupAudioListener();
    _startLevel(currentLevel);
  }

  void _setupGridDimensions(int level) {
    // مرحله ۱: ۲×۲ (۴ تکه)
    // مرحله ۲: ۳×۳ (۹ تکه)
    // ...
    // مرحله ۹: ۱۰×۱۰ (۱۰۰ تکه)
    // مرحله ۱۰ و بالاتر: ثابت روی ۱۰×۱۰
    int dim = level + 1;
    if (dim > 10) dim = 10;
    rows = dim;
    cols = dim;
    totalPieces = rows * cols;
  }

  void _setupAudioListener() {
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (!_isLevelComplete && !_dialogShown && mounted) {
        _showGameOverDialog();
      }
    });
  }

  Future<void> _startLevel(int level, {bool reuseAudio = false, bool reuseImage = false}) async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = "";
      downloadProgress = null;
      downloadedBytes = 0;
      _isLevelComplete = false;
      _dialogShown = false;
      currentLevel = level;
      _setupGridDimensions(level);
      placedPieces = List<PuzzlePieceData?>.filled(totalPieces, null);
      remainingPieces = [];
    });

    try {
      await _audioPlayer.stop();

      // ۱. دانلود تصویر پازل
      if (!reuseImage || currentImageBytes == null) {
        setState(() => loadingStatus = "در حال دریافت تصویر مرحله...");
        currentImageBytes = await AssetManager.fetchRandomImage(
          onProgress: (received, total) {
            if (mounted) {
              setState(() {
                downloadedBytes = received;
                if (total > 0) {
                  downloadProgress = (received / total) * 0.5;
                } else {
                  downloadProgress = null;
                }
              });
            }
          },
        );
      }

      // ۲. دانلود صوت
      if (!reuseAudio || currentAudioPath == null) {
        setState(() => loadingStatus = "در حال دریافت نوا...");
        currentAudioPath = await AssetManager.fetchRandomMusic(
          onProgress: (received, total) {
            if (mounted) {
              setState(() {
                downloadedBytes = received;
                if (total > 0) {
                  downloadProgress = 0.5 + ((received / total) * 0.5);
                } else {
                  downloadProgress = null;
                }
              });
            }
          },
        );
      }

      setState(() => loadingStatus = "برش و آماده‌سازی قطعات پازل...");

      // ۳. برش تصویر بر اساس ردیف و ستون
      final pieces = PuzzleHelper.splitImage(
        inputBytes: currentImageBytes!,
        rows: rows,
        cols: cols,
      );

      pieces.shuffle();

      setState(() {
        remainingPieces = pieces;
        isLoading = false;
      });

      // ۴. اجرای صوت
      if (currentAudioPath != null) {
        await _audioPlayer.play(DeviceFileSource(currentAudioPath!));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = "سرعت اینترنت ضعیف است یا اتصال قطع شد.\nلطفاً دوباره امتحان کنید.";
        });
      }
    }
  }

  void _onPiecePlaced(int targetIndex, PuzzlePieceData piece) {
    if (piece.index == targetIndex) {
      setState(() {
        placedPieces[targetIndex] = piece;
        remainingPieces.removeWhere((p) => p.index == piece.index);
      });

      // بررسی برنده شدن در پازل
      if (!placedPieces.contains(null)) {
        _isLevelComplete = true;
        _audioPlayer.stop();
        _saveProgressAndShowSuccess();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("جای این تکه اینجا نیست، بیشتر دقت کن!", textDirection: TextDirection.rtl),
          duration: Duration(milliseconds: 600),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _saveProgressAndShowSuccess() async {
    // ذخیره آنلاک شدن مرحله بعد
    final prefs = await SharedPreferences.getInstance();
    final String key = 'max_unlocked_level_${widget.playerName}';
    final int currentMax = prefs.getInt(key) ?? 1;
    if (currentLevel >= currentMax && currentLevel < 10) {
      await prefs.setInt(key, currentLevel + 1);
    }

    _showSuccessDialog();
  }

  void _showGameOverDialog() {
    _dialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("زمان آهنگ تمام شد! ⏳", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "هنوز پازل کامل نشده است. کدام حالت را برای ادامه انتخاب می‌کنی؟",
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowButtonSpacing: 10,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            icon: const Icon(Icons.replay),
            label: const Text("۱. تکرار همین پازل و همین آهنگ"),
            onPressed: () {
              Navigator.pop(ctx);
              _startLevel(currentLevel, reuseAudio: true, reuseImage: true);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            icon: const Icon(Icons.music_note),
            label: const Text("۲. همین پازل با آهنگ جدید"),
            onPressed: () {
              Navigator.pop(ctx);
              _startLevel(currentLevel, reuseAudio: false, reuseImage: true);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent, foregroundColor: Colors.white),
            icon: const Icon(Icons.refresh),
            label: const Text("۳. پازل جدید و آهنگ جدید"),
            onPressed: () {
              Navigator.pop(ctx);
              _startLevel(currentLevel, reuseAudio: false, reuseImage: false);
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("آفرین قهرمان! 🎉", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        content: Text(
          "مرحله $currentLevel را با موفقیت تمام کردی!",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx); // بستن دیالوگ
              Navigator.pop(context); // بازگشت به نقشه مراحل
            },
            child: const Text("لیست مراحل 🗺️"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _startLevel(currentLevel + 1);
            },
            child: const Text("مرحله بعدی 🚀"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // غیرفعال کردن روشن ماندن دائم صفحه هنگام خروج از بازی
    WakelockPlus.disable();
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("مرحله $currentLevel ($rows×$cols)"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: hasError
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 70, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () => _startLevel(currentLevel),
                      icon: const Icon(Icons.refresh),
                      label: const Text("تلاش مجدد"),
                    )
                  ],
                ),
              ),
            )
          : isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(loadingStatus, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        LinearProgressIndicator(
                          value: downloadProgress,
                          backgroundColor: Colors.grey.shade300,
                          color: Colors.deepPurple,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          downloadProgress != null
                              ? "${(downloadProgress! * 100).toInt()}%"
                              : "${(downloadedBytes / 1024).toStringAsFixed(1)} KB بارگیری شد...",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // قاب پازل اصلی در بالا
                    Expanded(
                      flex: 5,
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.deepPurple.shade300, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: totalPieces,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 1.0,
                                  mainAxisSpacing: 1.0,
                                ),
                                itemBuilder: (context, index) {
                                  final piece = placedPieces[index];
                                  return DragTarget<PuzzlePieceData>(
                                    onWillAcceptWithDetails: (details) => placedPieces[index] == null,
                                    onAcceptWithDetails: (details) => _onPiecePlaced(index, details.data),
                                    builder: (context, candidateData, rejectedData) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: piece != null ? Colors.transparent : Colors.white.withOpacity(0.9),
                                          border: Border.all(color: Colors.grey.shade300, width: 0.5),
                                        ),
                                        child: piece != null
                                            ? Image.memory(piece.imageBytes, fit: BoxFit.fill)
                                            : Center(
                                                child: Text(
                                                  "${index + 1}",
                                                  style: TextStyle(
                                                    color: Colors.grey.shade400,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: rows >= 6 ? 9 : 14,
                                                  ),
                                                ),
                                              ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Divider(height: 1, thickness: 1.5),

                    // مخزن قطعات در پایین
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        color: Colors.deepPurple.withOpacity(0.04),
                        child: remainingPieces.isEmpty
                            ? const Center(
                                child: Text(
                                  "آفرین! همه تکه‌ها با موفقیت قرار گرفتند 👏",
                                  style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              )
                            : GridView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: remainingPieces.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols >= 5 ? 5 : 4,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 6,
                                  mainAxisSpacing: 6,
                                ),
                                itemBuilder: (context, index) {
                                  final piece = remainingPieces[index];
                                  return Draggable<PuzzlePieceData>(
                                    data: piece,
                                    feedback: Material(
                                      elevation: 10,
                                      borderRadius: BorderRadius.circular(6),
                                      child: SizedBox(
                                        width: 70,
                                        height: 70,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: Image.memory(piece.imageBytes, fit: BoxFit.fill),
                                        ),
                                      ),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.2,
                                      child: Image.memory(piece.imageBytes, fit: BoxFit.fill),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 3,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.memory(piece.imageBytes, fit: BoxFit.fill),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
