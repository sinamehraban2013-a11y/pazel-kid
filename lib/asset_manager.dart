import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

typedef ProgressCallback = void Function(int received, int total);

class AssetManager {
  static const String scriptBaseUrl =
      "https://script.google.com/macros/s/AKfycbwBLyDbJu78M_nxaZtfcfFtd6DSMp6yl3Lu2lPOPwimuDynqGN8cTvZr4JpN3eJhxGA/exec";

  static const String imageFolderId = "1CHlj2vLFuc-JjHAKREjcQ-YfZVO3ueBh";
  static const String audioFolderId = "1tFPotXvU0NxyR8Jqsh8SPI3DZakKps08";

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 60),
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
          // در نسخه وب فقط این آدرس هدر CORS دارد
          String downloadUrl = item['downloadUrl'] ??
              (kIsWeb
                  ? "https://drive.usercontent.google.com/download?id=$fileId&export=download"
                  : "https://drive.google.com/uc?export=download&id=$fileId");

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
      lastListError = e.toString();
      return [];
    }
  }

  static String lastListError = '';
  static Uint8List? webAudioBytes;

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

  static String _webFallback(String url, int attempt) {
    if (!kIsWeb || attempt < 2) return url;
    final id = Uri.tryParse(url)?.queryParameters['id'];
    return id == null ? url : 'https://lh3.googleusercontent.com/d/$id';
  }

  static Future<Uint8List> fetchRandomImage({ProgressCallback? onProgress}) async {
    int attempts = 0;
    while (attempts < 2) {
      try {
        attempts++;
        if (cachedImageUrls.isEmpty) {
          cachedImageUrls = await _fetchFolderFileUrls(imageFolderId, 'image');
        }
        if (cachedImageUrls.isEmpty) {
          throw Exception('فهرست تصاویر دریافت نشد $lastListError');
        }

        final random = Random();
        final String selectedImageUrl = cachedImageUrls[random.nextInt(cachedImageUrls.length)];

        final response = await _dio.get<List<int>>(
          _webFallback(selectedImageUrl, attempts),
          options: Options(responseType: ResponseType.bytes),
          onReceiveProgress: onProgress,
        );

        if (response.statusCode == 200 && response.data != null) {
          return Uint8List.fromList(response.data!);
        }
      } catch (e) {
        if (attempts >= 2) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('خطا در بارگیری تصویر پس از تلاش مجدد');
  }

  static Future<String> fetchRandomMusic({ProgressCallback? onProgress}) async {
    int attempts = 0;
    while (attempts < 2) {
      try {
        attempts++;
        if (cachedAudioUrls.isEmpty) {
          cachedAudioUrls = await _fetchFolderFileUrls(audioFolderId, 'audio');
        }
        if (cachedAudioUrls.isEmpty) {
          throw Exception('فهرست صوت‌ها دریافت نشد $lastListError');
        }

        final random = Random();
        final String selectedAudioUrl = cachedAudioUrls[random.nextInt(cachedAudioUrls.length)];
        if (kIsWeb) {
          final r = await _dio.get<List<int>>(
            selectedAudioUrl,
            options: Options(responseType: ResponseType.bytes),
            onReceiveProgress: onProgress,
          );
          webAudioBytes = Uint8List.fromList(r.data!);
          return selectedAudioUrl;
        }
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
      } catch (e) {
        if (attempts >= 2) rethrow;
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception('خطا در بارگیری صوت پس از تلاش مجدد');
  }
}
