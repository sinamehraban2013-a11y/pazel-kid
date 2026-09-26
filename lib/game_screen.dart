import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:saver_gallery/saver_gallery.dart';

import 'asset_manager.dart';
import 'puzzle_helper.dart';
import 'reward_service.dart';

class GameScreen extends StatefulWidget {
  final String playerName;
  final int level;

  const GameScreen({
    Key? key,
    required this.playerName,
    required this.level,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late int currentLevel;
  int gridSize = 3;

  bool isLoading = true;
  String loadingMessage = 'در حال آماده‌سازی بازی...';

  Uint8List? currentImageBytes;
  String? currentAudioPath;

  List<PuzzlePieceData> allPieces = [];
  List<PuzzlePieceData?> boardSlots = [];
  List<PuzzlePieceData> trayPieces = [];

  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _completeSub;

  late ConfettiController _confettiController;

  bool _isSolved = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    currentLevel = widget.level;
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    WakelockPlus.enable();
    _initLevel();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _completeSub?.cancel();
    _audioPlayer.dispose();
    _confettiController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _calculateGridSize() {
    if (currentLevel <= 3) {
      gridSize = 3;
    } else if (currentLevel <= 7) {
      gridSize = 4;
    } else {
      gridSize = 5;
    }
  }

  Future<void> _initLevel() async {
    setState(() {
      isLoading = true;
      loadingMessage = 'در حال دریافت تصویر و صوت مرحله $currentLevel...';
      _isSolved = false;
      _showPreview = false;
      boardSlots = [];
      trayPieces = [];
      allPieces = [];
    });

    _calculateGridSize();

    try {
      await _audioPlayer.stop();

      // ۱. بارگذاری تصویر
      setState(() {
        loadingMessage = 'در حال دریافت تصویر جورچین...';
      });
      final imgBytes = await AssetManager.fetchRandomImage();
      if (imgBytes == null) {
        throw Exception('عدم امکان بارگذاری تصویر جورچین.');
      }
      currentImageBytes = imgBytes;

      // ۲. برش قطعات جورچین
      setState(() {
        loadingMessage = 'در حال آماده‌سازی و برش قطعات...';
      });
     
      final pieces = PuzzleHelper.splitImage(
        inputBytes: imgBytes,
        rows: gridSize,
        cols: gridSize,
      );

      allPieces = List.from(pieces);
      boardSlots = List<PuzzlePieceData?>.filled(gridSize * gridSize, null);
      trayPieces = List.from(pieces)..shuffle(Random());

      // ۳. بارگذاری و پخش صوت
      setState(() {
        loadingMessage = 'در حال بارگذاری صوت مرحله...';
      });
      final audioPath = await AssetManager.fetchRandomMusic();
      currentAudioPath = audioPath;

      if (audioPath != null && File(audioPath).existsSync()) {
        await _audioPlayer.setSource(DeviceFileSource(audioPath));

        _durSub?.cancel();
        _durSub = _audioPlayer.onDurationChanged.listen((dur) {
          if (mounted) setState(() => _totalDuration = dur);
        });

        _posSub?.cancel();
        _posSub = _audioPlayer.onPositionChanged.listen((pos) {
          if (mounted) setState(() => _currentPosition = pos);
        });

        _completeSub?.cancel();
        _completeSub = _audioPlayer.onPlayerComplete.listen((_) {
          _onTimeExpired();
        });

        await _audioPlayer.resume();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        loadingMessage = 'خطایی رخ داد: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در آماده‌سازی مرحله: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTimeExpired() {
    if (_isSolved || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('پایان زمان مرحله! ⏳'),
          content: const Text(
            'زمان پخش صوت به پایان رسید و جورچین تکمیل نشد. تمایل دارید مجدداً تلاش کنید؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('خروج به انتخاب مرحله'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _initLevel();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                foregroundColor: Colors.white,
              ),
              child: const Text('تلاش دوباره'),
            ),
          ],
        ),
      ),
    );
  }

  void _checkSolution() {
    for (int i = 0; i < boardSlots.length; i++) {
      if (boardSlots[i] == null || boardSlots[i]!.index != i) {
        return;
      }
    }

    _isSolved = true;
    _audioPlayer.pause();
    _confettiController.play();
    _saveProgress();
    _showSuccessDialog();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUnlocked =
        prefs.getInt('max_unlocked_level_${widget.playerName}') ?? 1;

    if (currentLevel >= currentUnlocked && currentLevel < 10) {
      await prefs.setInt(
          'max_unlocked_level_${widget.playerName}', currentLevel + 1);
    }

    await RewardService.unlockReward(currentLevel);
  }

  Future<bool> _saveCurrentPuzzleImageToGallery() async {
    final imageBytes = currentImageBytes;
    if (imageBytes == null) return false;

    try {
      final result = await SaverGallery.saveImage(
        imageBytes,
        quality: 100,
        fileName:
            'puzzle_level_${currentLevel}_${DateTime.now().millisecondsSinceEpoch}.png',
        androidRelativePath: 'Pictures/جورچین اندیشه',
        skipIfExists: false,
      );
      return result.isSuccess;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _saveCurrentAudioToGallery() async {
    final audioPath = currentAudioPath;
    if (audioPath == null) return false;

    try {
      final result = await SaverGallery.saveFile(
        filePath: audioPath,
        fileName:
            'puzzle_audio_level_${currentLevel}_${DateTime.now().millisecondsSinceEpoch}.mp3',
        androidRelativePath: 'Music/جورچین اندیشه',
        skipIfExists: false,
      );
      return result.isSuccess;
    } catch (_) {
      return false;
    }
  }

  void _showSuccessDialog() {
    final cardPath = RewardService.getCardAssetPath(currentLevel);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(
            child: Text(
              '🎉 تبریک، شما برنده شدید! 🎉',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF8A00),
                fontSize: 18,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'آفرین قهرمان! جورچین این مرحله را با موفقیت حل کردی.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    cardPath,
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: Colors.orange.shade100,
                      alignment: Alignment.center,
                      child: const Text('کارت پاداش مرحله'),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // دکمه ۱: ذخیره کارت در گالری
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A00),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text('ذخیره کارت در گالری'),
                  onPressed: () async {
                    final ok = await RewardService.saveCardToGallery(cardPath);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'کارت جایزه در گالری ذخیره شد 🖼️'
                                : 'ذخیره کارت جایزه ناموفق بود ❌',
                            textAlign: TextAlign.center,
                          ),
                          backgroundColor: ok ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),

                // دکمه ۲: ذخیره عکس جورچین در گالری
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.image_rounded, size: 20),
                  label: const Text('ذخیره عکس جورچین در گالری'),
                  onPressed: () async {
                    final ok = await _saveCurrentPuzzleImageToGallery();
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'عکس جورچین در گالری ذخیره شد ✅'
                                : 'ذخیره عکس جورچین ناموفق بود ❌',
                            textAlign: TextAlign.center,
                          ),
                          backgroundColor: ok ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),

                // دکمه ۳: ذخیره صوت این مرحله در گالری
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.music_note_rounded, size: 20),
                  label: const Text('ذخیره صوت این مرحله در گالری'),
                  onPressed: () async {
                    final ok = await _saveCurrentAudioToGallery();
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'فایل صوتی مرحله ذخیره شد 🎵'
                                : 'ذخیره صوت ناموفق بود ❌',
                            textAlign: TextAlign.center,
                          ),
                          backgroundColor: ok ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('لیست مراحل'),
            ),
            if (currentLevel < 10)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    currentLevel++;
                  });
                  _initLevel();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('مرحله بعد ❯'),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boardDim = min(size.width * 0.9, 360.0);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8E7),
        appBar: AppBar(
          title: Text('مرحله $currentLevel (${gridSize}x$gridSize)'),
          backgroundColor: const Color(0xFFFF8A00),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
          actions: [
            IconButton(
              icon: Icon(
                _showPreview
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
              tooltip: 'پیش‌نمایش تصویر کامل',
              onPressed: () {
                setState(() {
                  _showPreview = !_showPreview;
                });
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFFFF8A00),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loadingMessage,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // نوار زمان و پیشرفت صدا
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        color: Colors.white,
                        child: Row(
                          children: [
                            const Icon(Icons.timer_rounded,
                                color: Color(0xFFFF8A00), size: 22),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(_currentPosition),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6),
                                ),
                                child: Slider(
                                  value: _currentPosition.inSeconds
                                      .toDouble()
                                      .clamp(
                                          0.0,
                                          max(_totalDuration.inSeconds.toDouble(),
                                              1.0)),
                                  max: max(
                                      _totalDuration.inSeconds.toDouble(), 1.0),
                                  activeColor: const Color(0xFFFF8A00),
                                  inactiveColor: Colors.orange.shade100,
                                  onChanged: null,
                                ),
                              ),
                            ),
                            Text(
                              _formatDuration(_totalDuration),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ناحیه تخته اصلی جورچین
                      Center(
                        child: SizedBox(
                          width: boardDim,
                          height: boardDim,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFFF8A00),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(4),
                                  itemCount: gridSize * gridSize,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: gridSize,
                                    crossAxisSpacing: 3,
                                    mainAxisSpacing: 3,
                                  ),
                                  itemBuilder: (context, slotIndex) {
                                    final piece = boardSlots[slotIndex];

                                    return DragTarget<PuzzlePieceData>(
                                      onWillAcceptWithDetails: (details) =>
                                          boardSlots[slotIndex] == null,
                                      onAcceptWithDetails: (details) {
                                        setState(() {
                                          final incoming = details.data;
                                          trayPieces.removeWhere(
                                              (p) => p.index == incoming.index);
                                          for (int i = 0;
                                              i < boardSlots.length;
                                              i++) {
                                            if (boardSlots[i]?.index ==
                                                incoming.index) {
                                              boardSlots[i] = null;
                                            }
                                          }
                                          boardSlots[slotIndex] = incoming;
                                        });
                                        _checkSolution();
                                      },
                                      builder: (context, candidate, rejected) {
                                        if (piece != null) {
                                          return Draggable<PuzzlePieceData>(
                                            data: piece,
                                            feedback: Material(
                                              color: Colors.transparent,
                                              child: SizedBox(
                                                width: (boardDim / gridSize) - 4,
                                                height:
                                                    (boardDim / gridSize) - 4,
                                                child: Image.memory(
                                                  piece.imageBytes,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            childWhenDragging: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Image.memory(
                                                piece.imageBytes,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        }

                                        return Container(
                                          decoration: BoxDecoration(
                                            color: candidate.isNotEmpty
                                                ? Colors.orange.shade100
                                                : const Color(0xFFFFF3E0),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: candidate.isNotEmpty
                                                  ? const Color(0xFFFF8A00)
                                                  : Colors.orange.shade200,
                                              width: 1.2,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${slotIndex + 1}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade300,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),

                              // حالت پیش‌نمایش شفاف با زدن چشم
                              if (_showPreview && currentImageBytes != null)
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Opacity(
                                      opacity: 0.88,
                                      child: Image.memory(
                                        currentImageBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // سینی قطعات برای جابه‌جایی با انگشت
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, -3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'قطعات جورچین:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF5D4037),
                                    ),
                                  ),
                                  Text(
                                    '${trayPieces.length} قطعه باقی‌مانده',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: trayPieces.map<Widget>((PuzzlePieceData piece) {
                                      final pieceSize =
                                          (boardDim / gridSize) - 6;

                                      return Draggable<PuzzlePieceData>(
                                        data: piece,
                                        feedback: Material(
                                          color: Colors.transparent,
                                          child: SizedBox(
                                            width: pieceSize,
                                            height: pieceSize,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.memory(
                                                piece.imageBytes,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        childWhenDragging: Opacity(
                                          opacity: 0.3,
                                          child: SizedBox(
                                            width: pieceSize,
                                            height: pieceSize,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.memory(
                                                piece.imageBytes,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                        child: Container(
                                          width: pieceSize,
                                          height: pieceSize,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.08),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.memory(
                                              piece.imageBytes,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

            // بارش جشن پیروزی
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
