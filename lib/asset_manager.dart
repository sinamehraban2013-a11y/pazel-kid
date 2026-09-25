import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

typedef ProgressCallback = void Function(int received, int total);

class AssetManager {
  static const String scriptBaseUrl =
      "https://script.google.com/macros/s/AKfycbwBLyDbJu78M_nxaZtfcfFtd6DSMp6yl3Lu2lPOPwimuDynqGN8cTvZr4JpN3eJhxGA/exec";

  static const String imageFolderId = "1CHlj2vLFuc-JjHAKREjcQ-YfZVO3ueBh";
  static const String audioFolderId = "1tFPotXvU0NxyR8Jqsh8SPI3DZakKps08";

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 40),
      followRedirects: true,
      maxRedirects: 10,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  static List<String> cachedImageUrls = [];
  static List<String> cachedAudioUrls = [];

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
      return [];
    }
  }

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
      return false;
    }
  }

  static Future<Uint8List> fetchRandomImage({ProgressCallback? onProgress}) async {
    if (cachedImageUrls.isEmpty) {
      cachedImageUrls = await _fetchFolderFileUrls(imageFolderId, 'image');
    }
    if (cachedImageUrls.isEmpty) {
      throw Exception('فهرست تصاویر در دسترس نیست');
    }

    final random = Random();
    final String selectedImageUrl = cachedImageUrls[random.nextInt(cachedImageUrls.length)];

    final response = await _dio.get<List<int>>(
      selectedImageUrl,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: onProgress,
    );

    if (response.statusCode == 200 && response.data != null) {
      return Uint8List.fromList(response.data!);
    }
    throw Exception('خطا در دریافت تصویر');
  }

  static Future<String> fetchRandomMusic({ProgressCallback? onProgress}) async {
    if (cachedAudioUrls.isEmpty) {
      cachedAudioUrls = await _fetchFolderFileUrls(audioFolderId, 'audio');
    }
    if (cachedAudioUrls.isEmpty) {
      throw Exception('فهرست اصوات در دسترس نیست');
    }

    final random = Random();
    final String selectedAudioUrl = cachedAudioUrls[random.nextInt(cachedAudioUrls.length)];
    final dir = await getTemporaryDirectory();
    final String localAudioPath = "${dir.path}/puzzle_aud_${DateTime.now().millisecondsSinceEpoch}.mp3";

    await _dio.download(
      selectedAudioUrl,
      localAudioPath,
      options: Options(responseType: ResponseType.bytes),
      onReceiveProgress: onProgress,
    );

    if (await File(localAudioPath).exists()) {
      return localAudioPath;
    }
    throw Exception('خطا در ذخیره‌سازی فایل صوتی');
  }
}
