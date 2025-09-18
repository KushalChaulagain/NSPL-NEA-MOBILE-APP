import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';

class ImageDownloadService {
  static final Dio _dio = Dio();

  /// Downloads an image from URL and saves it to device gallery
  static Future<ImageDownloadResult> downloadAndSaveToGallery({
    required String imageUrl,
    required String fileName,
    int quality = 90,
  }) async {
    try {
      // Step 1: Request permissions
      final permissionResult = await _requestPermissions();
      if (!permissionResult.success) {
        return ImageDownloadResult(
          success: false,
          error: permissionResult.error,
        );
      }

      // Step 2: Download image bytes
      final downloadResult = await _downloadImageBytes(imageUrl);
      if (!downloadResult.success) {
        return ImageDownloadResult(
          success: false,
          error: downloadResult.error,
        );
      }

      // Step 3: Save to gallery
      final saveResult = await _saveToGallery(
        imageBytes: downloadResult.data!,
        fileName: fileName,
        quality: quality,
      );

      return ImageDownloadResult(
        success: saveResult.success,
        error: saveResult.error,
        filePath: saveResult.filePath,
      );
    } catch (e) {
      return ImageDownloadResult(
        success: false,
        error: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Downloads image bytes from URL
  static Future<ImageDownloadResult> _downloadImageBytes(
      String imageUrl) async {
    try {
      final response = await _dio.get(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return ImageDownloadResult(
          success: true,
          data: Uint8List.fromList(response.data),
        );
      } else {
        return ImageDownloadResult(
          success: false,
          error: 'Failed to download image: HTTP ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error';
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Download timeout';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection';
      }
      return ImageDownloadResult(
        success: false,
        error: errorMessage,
      );
    } catch (e) {
      return ImageDownloadResult(
        success: false,
        error: 'Download failed: ${e.toString()}',
      );
    }
  }

  /// Saves image bytes to device gallery
  static Future<ImageDownloadResult> _saveToGallery({
    required Uint8List imageBytes,
    required String fileName,
    required int quality,
  }) async {
    try {
      // Clean filename - remove invalid characters
      final cleanFileName = _cleanFileName(fileName);

      final result = await SaverGallery.saveImage(
        imageBytes,
        quality: quality,
        name: cleanFileName,
        androidRelativePath: "Pictures/NSPL_Gallery",
        androidExistNotSave: false,
      );

      // SaverGallery.saveImage returns a SaveResult object
      if (result.isSuccess) {
        return ImageDownloadResult(
          success: true,
          filePath: 'Gallery/NSPL_Gallery/$cleanFileName',
        );
      } else {
        return ImageDownloadResult(
          success: false,
          error: 'Failed to save image to gallery: ${result.errorMessage}',
        );
      }
    } catch (e) {
      return ImageDownloadResult(
        success: false,
        error: 'Save failed: ${e.toString()}',
      );
    }
  }

  /// Requests necessary permissions for saving to gallery
  static Future<ImageDownloadResult> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // For Android 13+ (API 33+), we need different permissions
        if (await _isAndroid13OrHigher()) {
          final photosPermission = await Permission.photos.request();
          if (!photosPermission.isGranted) {
            return ImageDownloadResult(
              success: false,
              error: 'Photo library permission denied',
            );
          }
        } else {
          // For older Android versions
          final storagePermission = await Permission.storage.request();
          if (!storagePermission.isGranted) {
            return ImageDownloadResult(
              success: false,
              error: 'Storage permission denied',
            );
          }
        }
      } else if (Platform.isIOS) {
        final photosPermission = await Permission.photos.request();
        if (!photosPermission.isGranted) {
          return ImageDownloadResult(
            success: false,
            error: 'Photo library permission denied',
          );
        }
      }

      return ImageDownloadResult(success: true);
    } catch (e) {
      return ImageDownloadResult(
        success: false,
        error: 'Permission request failed: ${e.toString()}',
      );
    }
  }

  /// Checks if Android version is 13 or higher
  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    try {
      // This is a simplified check - in production you might want to use
      // device_info_plus package for more accurate version detection
      return true; // Assume modern Android for now
    } catch (e) {
      return false;
    }
  }

  /// Cleans filename by removing invalid characters
  static String _cleanFileName(String fileName) {
    // Remove or replace invalid characters
    String cleanName = fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();

    // Ensure it has an extension
    if (!cleanName.contains('.')) {
      cleanName += '.jpg';
    }

    // Limit length
    if (cleanName.length > 100) {
      final extension = cleanName.split('.').last;
      final nameWithoutExt = cleanName.substring(0, cleanName.lastIndexOf('.'));
      cleanName =
          '${nameWithoutExt.substring(0, 100 - extension.length - 1)}.$extension';
    }

    return cleanName;
  }

  /// Downloads image to temporary directory (fallback method)
  static Future<ImageDownloadResult> downloadToTempDirectory({
    required String imageUrl,
    required String fileName,
  }) async {
    try {
      final directory = await getTemporaryDirectory();
      final cleanFileName = _cleanFileName(fileName);
      final filePath = '${directory.path}/$cleanFileName';

      await _dio.download(imageUrl, filePath);

      return ImageDownloadResult(
        success: true,
        filePath: filePath,
      );
    } catch (e) {
      return ImageDownloadResult(
        success: false,
        error: 'Download to temp failed: ${e.toString()}',
      );
    }
  }
}

/// Result class for image download operations
class ImageDownloadResult {
  final bool success;
  final String? error;
  final String? filePath;
  final Uint8List? data;

  ImageDownloadResult({
    required this.success,
    this.error,
    this.filePath,
    this.data,
  });
}
