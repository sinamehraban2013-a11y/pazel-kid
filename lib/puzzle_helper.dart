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

    // کادربندی مربع مرکزی در صورت مساوی نبودن طول و عرض
    int minSide = decoded.width < decoded.height ? decoded.width : decoded.height;
    int offsetX = (decoded.width - minSide) ~/ 2;
    int offsetY = (decoded.height - minSide) ~/ 2;
    final img.Image squareImage = img.copyCrop(decoded, x: offsetX, y: offsetY, width: minSide, height: minSide);

    final int pieceWidth = squareImage.width ~/ cols;
    final int pieceHeight = squareImage.height ~/ rows;

    List<PuzzlePieceData> pieces = [];
    int counter = 0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final img.Image croppedPiece = img.copyCrop(
          squareImage,
          x: c * pieceWidth,
          y: r * pieceHeight,
          width: pieceWidth,
          height: pieceHeight,
        );

        final Uint8List piecePng = Uint8List.fromList(img.encodePng(croppedPiece));
        pieces.add(PuzzlePieceData(index: counter, imageBytes: piecePng));
        counter++;
      }
    }
    return pieces;
  }
}
