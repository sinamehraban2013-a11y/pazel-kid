import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'asset_manager.dart';
import 'puzzle_helper.dart';

class GameScreen extends StatefulWidget {
  final String playerName;

  const GameScreen({Key? key, required this.playerName}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int currentLevel = 1;
  int rows = 2;
  int cols = 2;
  int totalPieces = 4;

  bool isLoading = true;
  String loadingStatus = "در حال آماده‌سازی...";
  double downloadProgress = 0.0;

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
    _setupAudioListener();
    _startLevel(currentLevel);
  }

  void _setupGridDimensions(int level) {
    switch (level) {
      case 1:
        rows = 2;
        cols = 2; // 4 قطعه
        break;
      case 2:
        rows = 4;
        cols = 4; // 6 قطعه
        break;
      case 3:
        rows = 6;
        cols = 6; // 8 قطعه
        break;
      case 4:
        rows = 8;
        cols = 8; // 9 قطعه
        break;
      case 5:
        rows = 10;
        cols = 10; // 12 قطعه
        break;
      case 6:
      default:
        rows = 12;
        cols = 12; // 16 قطعه
        break;
    }
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
      downloadProgress = 0.0;
      _isLevelComplete = false;
      _dialogShown = false;
      currentLevel = level;
      _setupGridDimensions(level);
      placedPieces = List<PuzzlePieceData?>.filled(totalPieces, null);
      remainingPieces = [];
    });

    try {
      await _audioPlayer.stop();

      // ۱. دانلود تصویر (در صورت عدم استفاده مجدد)
      if (!reuseImage || currentImageBytes == null) {
        setState(() => loadingStatus = "در حال دریافت تصویر پازل...");
        currentImageBytes = await AssetManager.fetchRandomImage(
          onProgress: (received, total) {
            if (total > 0 && mounted) {
              setState(() => downloadProgress = (received / total) * 0.5);
            }
          },
        );
      }

      // ۲. دانلود صوت (در صورت عدم استفاده مجدد)
      if (!reuseAudio || currentAudioPath == null) {
        setState(() => loadingStatus = "در حال دریافت نوای صوتی...");
        currentAudioPath = await AssetManager.fetchRandomMusic(
          onProgress: (received, total) {
            if (total > 0 && mounted) {
              setState(() => downloadProgress = 0.5 + ((received / total) * 0.5));
            }
          },
        );
      }

      setState(() => loadingStatus = "آماده‌سازی قطعات پازل...");

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

      // ۴. شروع پخش صوت
      if (currentAudioPath != null) {
        await _audioPlayer.play(DeviceFileSource(currentAudioPath!));
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("خطا در بارگذاری مرحله: $e", textDirection: TextDirection.rtl),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _onPiecePlaced(int targetIndex, PuzzlePieceData piece) {
    if (piece.index == targetIndex) {
      setState(() {
        placedPieces[targetIndex] = piece;
        remainingPieces.removeWhere((p) => p.index == piece.index);
      });

      // بررسی اتمام پازل
      if (!placedPieces.contains(null)) {
        _isLevelComplete = true;
        _audioPlayer.stop();
        _showSuccessDialog();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("جای این قطعه اینجا نیست، دوباره دقت کن!", textDirection: TextDirection.rtl),
          duration: Duration(milliseconds: 900),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showGameOverDialog() {
    _dialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("زمان آهنگ به پایان رسید! ⏳", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "هنوز پازل کامل نشده است. کدام حالت را برای ادامه انتخاب می‌کنی؟",
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Vazirmatn'),
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
            label: const Text("۲. همین پازل با آهنگ جدید (زمان بیشتر)"),
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
          "مرحله $currentLevel را با موفقیت حل کردی!",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
              onPressed: () {
                Navigator.pop(ctx);
                _startLevel(currentLevel + 1);
              },
              child: const Text("رفتن به مرحله بعد 🚀", style: TextStyle(fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _playerCompleteSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("مرحله $currentLevel ($totalPieces تکه) - بازیکن: ${widget.playerName}"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(loadingStatus, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: downloadProgress > 0 ? downloadProgress : null,
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.deepPurple,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${(downloadProgress * 100).toInt()}%",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.deepPurple),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // بخش بالایی: صفحه مقصد پازل (با امکان زوم دو انگشتی)
                Expanded(
                  flex: 5,
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.deepPurple.shade200, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.8,
                        maxScale: 3.0,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: cols / rows,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(4),
                              itemCount: totalPieces,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                              ),
                              itemBuilder: (context, index) {
                                final piece = placedPieces[index];
                                return DragTarget<PuzzlePieceData>(
                                  onWillAcceptWithDetails: (details) => placedPieces[index] == null,
                                  onAcceptWithDetails: (details) => _onPiecePlaced(index, details.data),
                                  builder: (context, candidateData, rejectedData) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: piece != null ? Colors.transparent : Colors.white70,
                                        border: Border.all(color: Colors.deepPurple.shade100, width: 1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: piece != null
                                          ? Image.memory(piece.imageBytes, fit: BoxFit.fill)
                                          : Center(
                                              child: Text(
                                                "${index + 1}",
                                                style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold),
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
                ),

                const Divider(height: 2, thickness: 2),

                // بخش پایینی: مخزن قطعات باقی‌مانده (با قابلیت اسکرول و زوم دو انگشتی)
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.purple.shade50,
                    child: remainingPieces.isEmpty
                        ? const Center(child: Text("همه تکه‌ها چیده شدند! 🎉", style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)))
                        : InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.8,
                            maxScale: 2.5,
                            child: GridView.builder(
                              itemCount: remainingPieces.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols > 3 ? cols : 3,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                              ),
                              itemBuilder: (context, index) {
                                final piece = remainingPieces[index];
                                return Draggable<PuzzlePieceData>(
                                  data: piece,
                                  feedback: Material(
                                    elevation: 8,
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 90,
                                      height: 90,
                                      child: Image.memory(piece.imageBytes, fit: BoxFit.fill),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: Image.memory(piece.imageBytes, fit: BoxFit.fill),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))
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
                ),
              ],
            ),
    );
  }
}
