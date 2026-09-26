import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class MediaCacheService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 7),
    receiveTimeout: const Duration(seconds: 15),
  ));

  /// دریافت فایل (عکس یا صوت): ابتدا دانلود اینترنتی، در صورت نبود اینترنت بازگشت به فایل‌های قبلی
  static Future<File?> fetchMediaFile({
    required String onlineUrl,
    required String filePrefix, // 'puzzle_img_' یا 'puzzle_audio_'
    required String extension,  // '.png' یا '.mp3'
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/media_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    final localPath = '${cacheDir.path}/${filePrefix}_${DateTime.now().millisecondsSinceEpoch}$extension';

    try {
      // ۱. تلاش برای دریافت از مخزن اینترنتی
      final response = await _dio.download(onlineUrl, localPath);
      if (response.statusCode == 200) {
        return File(localPath);
      }
    } catch (e) {
      // اینترنت قطع است یا تایم‌اوت خورده است؛ به سراغ فایل‌های کش قبلی می‌رویم
    }

    // ۲. فالبک به فایل‌های ذخیره‌شده قبلی
    final localFiles = cacheDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains(filePrefix))
        .toList();

    if (localFiles.isNotEmpty) {
      final random = Random();
      return localFiles[random.nextInt(localFiles.length)];
    }

    return null; // در صورتی که نه اینترنت باشد و نه قبلاً فایلی دانلود شده باشد
  }
}
