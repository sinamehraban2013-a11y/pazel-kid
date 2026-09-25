import 'dart:typed_data';
import 'package:image/image.dart' as img;

class PuzzlePieceData {
  final int index;
  final Uint8List imageBytes;

  PuzzlePieceData({required this.index, required this.imageBytes});
}

class PuzzleHelper {
  static List<PuzzlePieceData> splitImage({
    required Uint8List inputBytes,
    required int rows,
    required int cols,
  }) {
    final img.Image? decoded = img.decodeImage(inputBytes);
    if (decoded == null) return [];

    // کادربندی مربع مرکزی دقیق
    final int minSide = decoded.width < decoded.height ? decoded.width : decoded.height;
    final int offsetX = (decoded.width - minSide) ~/ 2;
    final int offsetY = (decoded.height - minSide) ~/ 2;
    final img.Image squareImage = img.copyCrop(
      decoded,
      x: offsetX,
      y: offsetY,
      width: minSide,
      height: minSide,
    );

    final int baseWidth = squareImage.width ~/ cols;
    final int baseHeight = squareImage.height ~/ rows;

    List<PuzzlePieceData> pieces = [];
    int counter = 0;

    for (int r = 0; r < rows; r++) {
      final int startY = r * baseHeight;
      // برای سطر آخر، تمام پیکسل‌های باقیمانده تا انتهای تصویر محاسبه می‌شوند
      final int currentHeight = (r == rows - 1) ? (squareImage.height - startY) : baseHeight;

      for (int c = 0; c < cols; c++) {
        final int startX = c * baseWidth;
        // برای ستون آخر، تمام پیکسل‌های باقیمانده تا انتهای تصویر محاسبه می‌شوند
        final int currentWidth = (c == cols - 1) ? (squareImage.width - startX) : baseWidth;

        final img.Image croppedPiece = img.copyCrop(
          squareImage,
          x: startX,
          y: startY,
          width: currentWidth,
          height: currentHeight,
        );

        final Uint8List piecePng = Uint8List.fromList(img.encodePng(croppedPiece));
        pieces.add(PuzzlePieceData(index: counter, imageBytes: piecePng));
        counter++;
      }
    }
    return pieces;
  }
}
