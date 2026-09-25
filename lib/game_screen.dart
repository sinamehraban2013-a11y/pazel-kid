import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'player_service.dart';
import 'puzzle_helper.dart';
import 'asset_manager.dart';

class GameScreen extends StatefulWidget {
  final String playerName;
  final int initialLevel;

  const GameScreen({
    Key? key,
    required this.playerName,
    required this.initialLevel,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum GameStatus { loading, readyToStart, playing, won, lost }

class _GameScreenState extends State<GameScreen> {
  late int _currentLevel;
  GameStatus _status = GameStatus.loading;

  final AudioPlayer _audioPlayer = AudioPlayer();
  List<PuzzlePieceData> _correctGrid = [];
  List<PuzzlePieceData> _shuffledPieces = [];
  int _targetPiecesCount = 4;

  // نگهداری داده‌های پازل و صوت جاری برای استفاده در تلاش مجدد
  Uint8List? _currentImageBytes;
  String? _currentMusicPath;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.initialLevel;
    _prepareLevel();
    _setupAudioListener();
  }

  void _setupAudioListener() {
    _audioPlayer.onPlayerComplete.listen((_) {
      if (_status == GameStatus.playing) {
        _onTimeFinished();
      }
    });
  }

  Future<void> _prepareLevel() async {
    setState(() => _status = GameStatus.loading);
    _targetPiecesCount = 4 + ((_currentLevel - 1) * 2);

    try {
      final imgBytes = await AssetManager.fetchRandomImage(_currentLevel);
      final musicPath = await AssetManager.fetchRandomMusic(_currentLevel);

      _currentImageBytes = imgBytes;
      _currentMusicPath = musicPath;

      final pieces = await PuzzleHelper.splitImage(imgBytes, _targetPiecesCount);
      _correctGrid = List.from(pieces);

      _shuffledPieces = List.from(pieces)..shuffle();
      for (var p in _shuffledPieces) {
        p.isPlaced = false;
      }

      await _audioPlayer.setSource(DeviceFileSource(musicPath));

      setState(() => _status = GameStatus.readyToStart);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در بارگذاری اطلاعات مرحله! لطفاً اینترنت را بررسی کنید.')),
      );
    }
  }

  void _startLevel() {
    setState(() => _status = GameStatus.playing);
    _audioPlayer.resume();
  }

  void _onTimeFinished() {
    _audioPlayer.stop();
    setState(() => _status = GameStatus.lost);
    _showGameOverDialog();
  }

  /// دیالوگ سه گزینه‌ای هنگام تمام شدن زمان/آهنگ
  void _showGameOverDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFFFFF9E6),
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sentiment_dissatisfied, color: Color(0xFFFF8A00), size: 30),
              SizedBox(width: 8),
              Text(
                "عزیزم نیاز به تلاش بیشتر داری 🌱",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color(0xFF6B4226),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "آهنگ تموم شد! چطور ادامه بدیم؟",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF4A4A4A)),
              ),
              const SizedBox(height: 18),

              // گزینه ۱: تکرار همین پازل و همین آهنگ
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A00),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.replay_rounded),
                label: const Text("تلاش دوباره با همین آهنگ 🔁", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  _retrySamePuzzleAndAudio();
                },
              ),
              const SizedBox(height: 10),

              // گزینه ۲: همان پازل با یک آهنگ دیگر (فرصت بیشتر)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.music_note_rounded),
                label: const Text("همین پازل با آهنگ جدید 🎵", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  Navigator.pop(context);
                  await _retrySamePuzzleWithNewAudio();
                },
              ),
              const SizedBox(height: 10),

              // گزینه ۳: پازل و آهنگ کاملاً جدید
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.shuffle_rounded),
                label: const Text("پازل و آهنگ کاملاً جدید 🎲", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  _prepareLevel();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ریست قطعات و پخش مجدد همان آهنگ
  void _retrySamePuzzleAndAudio() {
    setState(() {
      for (var p in _correctGrid) {
        p.isPlaced = false;
      }
      _shuffledPieces = List.from(_correctGrid)..shuffle();
      _status = GameStatus.playing;
    });

    if (_currentMusicPath != null) {
      _audioPlayer.play(DeviceFileSource(_currentMusicPath!));
    }
  }

  /// نگه داشتن همان قطعات ولی دریافت و پخش آهنگ جدید
  Future<void> _retrySamePuzzleWithNewAudio() async {
    setState(() => _status = GameStatus.loading);
    try {
      final newMusicPath = await AssetManager.fetchRandomMusic(_currentLevel);
      _currentMusicPath = newMusicPath;

      await _audioPlayer.setSource(DeviceFileSource(newMusicPath));

      setState(() {
        for (var p in _correctGrid) {
          p.isPlaced = false;
        }
        _shuffledPieces = List.from(_correctGrid)..shuffle();
        _status = GameStatus.playing;
      });

      _audioPlayer.resume();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطا در دریافت آهنگ جدید! با همان آهنگ قبلی امتحان می‌کنیم.')),
      );
      _retrySamePuzzleAndAudio();
    }
  }

  void _onLevelCompleted() async {
    await _audioPlayer.stop();
    setState(() => _status = GameStatus.won);
    _currentLevel++;
    await PlayerService.updateLevel(_currentLevel);

    _showOutcomeDialog(
      title: "آفرین عزیز جان، یک چالش جدید خواهی داشت ⭐",
      buttonText: "مرحله بعدی 🚀",
      onPressed: () {
        Navigator.pop(context);
        _prepareLevel();
      },
    );
  }

  void _showOutcomeDialog({required String title, required String buttonText, required VoidCallback onPressed}) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFFF9E6),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6B4226)),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: onPressed,
            child: Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (rows, cols) = PuzzleHelper.getGridDimensions(_targetPiecesCount);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7BD5F5),
        elevation: 0,
        title: Text(
          '${widget.playerName} | مرحله $_currentLevel (${_targetPiecesCount} قطعه)',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _status == GameStatus.loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8A00)))
            : _status == GameStatus.readyToStart
                ? _buildInstructionView()
                : Column(
                    children: [
                      // نیمه بالایی: بستر قرارگیری صحیح قطعات
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                          ),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              childAspectRatio: 1.0,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                            itemCount: _correctGrid.length,
                            itemBuilder: (context, index) {
                              final targetPiece = _correctGrid[index];
                              return DragTarget<PuzzlePieceData>(
                                onWillAccept: (incoming) => incoming?.index == targetPiece.index,
                                onAccept: (incoming) {
                                  setState(() {
                                    targetPiece.isPlaced = true;
                                    if (_correctGrid.every((p) => p.isPlaced)) {
                                      _onLevelCompleted();
                                    }
                                  });
                                },
                                builder: (context, candidateData, rejectedData) {
                                  if (targetPiece.isPlaced) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(targetPiece.imageBytes, fit: BoxFit.cover),
                                    );
                                  }
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: candidateData.isNotEmpty ? const Color(0xFFB4F8C8) : const Color(0xFFE8ECEF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.black12, style: BorderStyle.solid),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.black26,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
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
                      const Divider(thickness: 2, color: Color(0xFF7BD5F5)),
                      // نیمه پایینی: قطعات غیرمرتب برای کشیدن
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              childAspectRatio: 1.0,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                            ),
                            itemCount: _shuffledPieces.length,
                            itemBuilder: (context, index) {
                              final piece = _shuffledPieces[index];
                              final isAlreadyPlaced = _correctGrid.firstWhere((p) => p.index == piece.index).isPlaced;

                              if (isAlreadyPlaced) {
                                return const SizedBox.shrink();
                              }

                              return Draggable<PuzzlePieceData>(
                                data: piece,
                                feedback: Material(
                                  elevation: 8,
                                  borderRadius: BorderRadius.circular(8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: Image.memory(piece.imageBytes, fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(piece.imageBytes, fit: BoxFit.cover),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(piece.imageBytes, fit: BoxFit.cover),
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

  Widget _buildInstructionView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_note_rounded, size: 70, color: Color(0xFFFF8A00)),
            const SizedBox(height: 16),
            const Text(
              'دوست عزیزم تا پایان پخش این قطعه موسیقی فرصت داری تا قطعه های پازل را از نیمه پایین تصویر برداشته و در نیمه بالایی تصویر به صورت مرتب بچینی، اگر حاضری روی دکمه شروع کلیک کن',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.6, fontWeight: FontWeight.w600, color: Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 5,
              ),
              onPressed: _startLevel,
              child: const Text('شروع بازی 🎮', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
