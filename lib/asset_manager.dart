import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class AssetManager {
  // لینک‌های اختصاصی دانلود (Google Drive Direct Link Format)
  static const String imageFolderId = "1CHlj2vLFuc-JjHAKREjcQ-YfZVO3ueBh";
  static const String audioFolderId = "1tFPotXvU0NxyR8Jqsh8SPI3DZakKps08";

  static final Dio _dio = Dio();

  static Future<Uint8List> fetchRandomImage(int level) async {
    // نمونه آدرس مستقیم بر اساس شناسه دریافتی
    final url = "https://drive.google.com/uc?export=download&id=$imageFolderId";
    final response = await _dio.get(url, options: Options(responseType: ResponseType.bytes));
    return Uint8List.fromList(response.data);
  }

  static Future<String> fetchRandomMusic(int level) async {
    final dir = await getTemporaryDirectory();
    final filePath = "${dir.path}/puzzle_track_$level.mp3";
    final url = "https://drive.google.com/uc?export=download&id=$audioFolderId";

    await _dio.download(url, filePath);
    return filePath;
  }
}
