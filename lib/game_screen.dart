import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'asset_manager.dart';
import 'puzzle_helper.dart';
import 'reward_service.dart';

class GameScreen extends StatefulWidget {
  final String playerName;
  final int initialLevel;

  const GameScreen({
    Key? key,
    required this.playerName,
    int? level,
    int? initialLevel,
  })  : initialLevel = initialLevel ?? level ?? 1,
        super(key: key);

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
  Duration _musicDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;

  bool _isLevelComplete = false;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    // فعال‌سازی روشن ماندن دائمی صفحه در حین بازی
    WakelockPlus.enable();

    currentLevel = widget.initialLevel;
    _setupAudioListeners();
    _startLevel(currentLevel);
  }

  void _setupGridDimensions(int level) {
    int dim = level + 1;
    if (dim > 10) dim = 10;
    rows = dim;
    cols = dim;
    totalPieces = rows * cols;
  }

  void _setupAudioListeners() {
    // گوش دادن به اتمام آهنگ
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (!_isLevelComplete && !_dialogShown && mounted) {
        _showGameOverDialog();
      }
    });

    // دریافت مدت زمان کل آهنگ
    _durationSubscription = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) {
        setState(() => _musicDuration = dur);
      }
    });

    // دریافت موقعیت زمانی لحظه‌ای جهت به‌روزرسانی تایمر
    _positionSubscription = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _currentPosition = pos);
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
      _musicDuration = Duration.zero;
      _currentPosition = Duration.zero;
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

      // ۳. برش تصویر
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

      // بررسی تکمیل پازل
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
    // ذخیره مرحله باز شده جدید
    final prefs = await SharedPreferences.getInstance();
    final String key = 'max_unlocked_level_${widget.playerName}';
    final int currentMax = prefs.getInt(key) ?? 1;
    if (currentLevel >= currentMax && currentLevel < 10) {
      await prefs.setInt(key, currentLevel + 1);
    }

    // ثبت کارت جایزه
    await RewardService.unlockReward(currentLevel);

    // دیالوگ موفقیت
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            icon: const Icon(Icons.grid_view_rounded),
            label: const Text("۴. بازگشت به انتخاب مراحل"),
            onPressed: () {
              Navigator.pop(ctx);
              _audioPlayer.stop();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showImagePreviewHint() {
    if (currentImageBytes == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "تصویر کامل پازل 🖼️",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            currentImageBytes!,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("متوجه شدم 👍"),
            ),
          )
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    final cardPath = RewardService.getCardAssetPath(currentLevel);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Column(
                children: [
                  const Text(
                    "آفرین قهرمان! 🎉",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "مرحله $currentLevel کامل شد و کارت حکمت آزاد گشت",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        cardPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              "تصویر کارت در پوشه assets/rewards یافت نشد.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(isSaving ? "در حال ذخیره..." : "ذخیره کارت در گالری"),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setDialogState(() => isSaving = true);
                              final ok = await RewardService.saveCardToGallery(cardPath);
                              setDialogState(() => isSaving = false);

                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok ? "عکس با موفقیت در گالری گوشی ذخیره شد ✅" : "خطا در ذخیره تصویر در گالری ❌",
                                      textAlign: TextAlign.center,
                                    ),
                                    backgroundColor: ok ? Colors.green : Colors.red,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text("لیست مراحل 🗺️"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startLevel(currentLevel + 1);
                  },
                  child: const Text("مرحله بعدی 🚀"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _playerCompleteSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // محاسبه زمان باقیمانده آهنگ برای تایمر معکوس
    final remainingSeconds = (_musicDuration - _currentPosition).inSeconds;
    final displaySeconds = remainingSeconds > 0 ? remainingSeconds : 0;
    final minutes = (displaySeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (displaySeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: Text("مرحله $currentLevel ($rows×$cols)"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: "بازگشت به انتخاب مراحل",
          onPressed: () {
            _audioPlayer.stop();
            Navigator.pop(context);
          },
        ),
        actions: [
          // ویجت تایمر معکوس آهنگ
          if (!isLoading && !hasError)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.amberAccent),
                  const SizedBox(width: 4),
                  Text(
                    "$minutes:$seconds",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          // دکمه راهنمای چشمی
          if (!isLoading && !hasError && currentImageBytes != null)
            IconButton(
              icon: const Icon(Icons.remove_red_eye_rounded, color: Colors.amberAccent, size: 26),
              tooltip: "مشاهده تصویر کامل",
              onPressed: _showImagePreviewHint,
            ),
        ],
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
