import 'dart:typed_data';
import 'package:image/image.dart' as img;

class PuzzlePieceData {
  final int index;
  final Uint8List imageBytes;
  bool isPlaced;

  PuzzlePieceData({required this.index, required this.imageBytes, this.isPlaced = false});
}

class PuzzleHelper {
  static (int rows, int cols) getGridDimensions(int pieceCount) {
    int cols = 2;
    int rows = pieceCount ~/ cols;
    return (rows, cols);
  }

  static Future<List<PuzzlePieceData>> splitImage(Uint8List imageBytes, int pieceCount) async {
    final (rows, cols) = getGridDimensions(pieceCount);
    img.Image? fullImage = img.decodeImage(imageBytes);
    if (fullImage == null) return [];

    int pieceWidth = fullImage.width ~/ cols;
    int pieceHeight = fullImage.height ~/ rows;

    List<PuzzlePieceData> pieces = [];
    int index = 0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        img.Image cropped = img.copyCrop(
          fullImage,
          x: c * pieceWidth,
          y: r * pieceHeight,
          width: pieceWidth,
          height: pieceHeight,
        );

        pieces.add(PuzzlePieceData(
          index: index++,
          imageBytes: Uint8List.fromList(img.encodePng(cropped)),
        ));
      }
    }
    return pieces;
  }
}
