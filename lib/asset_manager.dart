import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class AssetManager {
  // آدرس وب‌اپ گوگل اسکریپت
  static const String scriptBaseUrl =
      "https://script.google.com/macros/s/AKfycbwBLyDbJu78M_nxaZtfcfFtd6DSMp6yl3Lu2lPOPwimuDynqGN8cTvZr4JpN3eJhxGA/exec";

  // شناسه‌های دو پوشه تصاویر و صوت‌ها در گوگل درایو
  static const String imageFolderId = "*******";
  static const String audioFolderId = "*******";

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,
      maxRedirects: 10,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  // کش کردن لیست فایل‌ها برای جلوگیری از ریکوئست‌های تکراری و بالا بردن سرعت بازی
  static List<String> cachedImageUrls = [];
  static List<String> cachedAudioUrls = [];

  /// دریافت لیست فایل‌های یک پوشه از طریق وب‌اسکریپت
  static Future<List<String>> _fetchFolderFileUrls(String folderId, String filterType) async {
    try {
      final response = await _dio.get(
        scriptBaseUrl,
        queryParameters: {'folderId': folderId},
      );

      dynamic rawData = response.data;
      if (rawData is String) {
        rawData = jsonDecode(rawData);
      }

      if (rawData is List) {
        List<String> urls = [];
        for (var item in rawData) {
          final String fileType = item['type'] ?? '';
          final String fileId = item['id'] ?? '';
          final String name = (item['name'] ?? '').toString().toLowerCase();

          // ساخت لینک مستقیم دانلود
          String downloadUrl = item['downloadUrl'] ?? "https://drive.google.com/uc?export=download&id=$fileId";

          if (filterType == 'image') {
            if (fileType == 'image' ||
                name.endsWith('.jpg') ||
                name.endsWith('.jpeg') ||
                name.endsWith('.png') ||
                name.endsWith('.webp')) {
              urls.add(downloadUrl);
            }
          } else if (filterType == 'audio') {
            if (fileType == 'audio' ||
                name.endsWith('.mp3') ||
                name.endsWith('.wav') ||
                name.endsWith('.m4a') ||
                name.endsWith('.ogg')) {
              urls.add(downloadUrl);
            }
          }
        }
        return urls;
      }
      return [];
    } catch (e) {
      print("خطا در دریافت لیست فایل‌ها برای پوشه $folderId: $e");
      return [];
    }
  }

  /// آماده‌سازی و بارگذاری اولیه کش لیست فایل‌ها
  static Future<bool> preloadFileList() async {
    try {
      if (cachedImageUrls.isEmpty) {
        cachedImageUrls = await _fetchFolderFileUrls(imageFolderId, 'image');
      }
      if (cachedAudioUrls.isEmpty) {
        cachedAudioUrls = await _fetchFolderFileUrls(audioFolderId, 'audio');
      }
      return cachedImageUrls.isNotEmpty && cachedAudioUrls.isNotEmpty;
    } catch (e) {
      print("خطا در بارگذاری اولیه لیست فایل‌ها: $e");
      return false;
    }
  }

  /// دریافت و دانلود تصادفی تصویر و صوت برای یک مرحله
  static Future<Map<String, String>?> getLevelAssets() async {
    try {
      // اگر لیست فایل‌ها در حافظه کش نبود، دریافت شود
      if (cachedImageUrls.isEmpty || cachedAudioUrls.isEmpty) {
        bool loaded = await preloadFileList();
        if (!loaded) return null;
      }

      final random = Random();
      final String selectedImageUrl = cachedImageUrls[random.nextInt(cachedImageUrls.length)];
      final String selectedAudioUrl = cachedAudioUrls[random.nextInt(cachedAudioUrls.length)];

      final dir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String localImagePath = "${dir.path}/puzzle_img_$timestamp.jpg";
      final String localAudioPath = "${dir.path}/puzzle_aud_$timestamp.mp3";

      // دانلود هم‌زمان تصویر و صوت
      await Future.wait([
        _dio.download(
          selectedImageUrl,
          localImagePath,
          options: Options(responseType: ResponseType.bytes),
        ),
        _dio.download(
          selectedAudioUrl,
          localAudioPath,
          options: Options(responseType: ResponseType.bytes),
        ),
      ]);

      // اطمینان از وجود فایل‌ها پس از دانلود
      if (await File(localImagePath).exists() && await File(localAudioPath).exists()) {
        return {
          'image': localImagePath,
          'audio': localAudioPath,
        };
      }
      return null;
    } catch (e) {
      print("خطا در دانلود دارایی‌های مرحله: $e");
      return null;
    }
  }
}
