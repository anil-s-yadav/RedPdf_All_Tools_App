import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_scanner/media_scanner.dart';

class FileUtils {
  /// Returns a unique file path by appending (n) if the file already exists.
  static Future<String> getUniqueFilePath(
    String directoryPath,
    String fileName,
  ) async {
    String name = p.basenameWithoutExtension(fileName);
    String extension = p.extension(fileName);
    String newPath = p.join(directoryPath, fileName);

    int counter = 1;
    File file = File(newPath);

    while (await file.exists()) {
      newPath = p.join(directoryPath, '$name($counter)$extension');
      file = File(newPath);
      counter++;
    }

    return newPath;
  }

  /// Saves a file to the Downloads/RedPdf folder.
  /// Returns the path of the saved file if successful.
  static Future<String?> saveToDevice({
    required String sourcePath,
    required String fileName,
  }) async {
    try {
      // 1. Handle Permissions for Android
      if (Platform.isAndroid) {
        if (!await Permission.manageExternalStorage.isGranted) {
          final status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            throw Exception('Storage permission denied');
          }
        }
        if (!await Permission.storage.isGranted) {
          await Permission.storage.request();
        }
      }

      // 2. Get Downloads Path
      String downloadsPath;
      if (Platform.isAndroid) {
        downloadsPath = '/storage/emulated/0/Download';
      } else {
        final dir = await getDownloadsDirectory();
        if (dir == null) {
          throw Exception('Could not find downloads directory');
        }
        downloadsPath = dir.path;
      }

      // 3. Create RedPdf folder
      final redPdfDir = Directory('$downloadsPath/RedPdf');
      if (!await redPdfDir.exists()) {
        await redPdfDir.create(recursive: true);
      }

      // 4. Get unique path to avoid overwriting
      final uniquePath = await getUniqueFilePath(redPdfDir.path, fileName);

      // 5. Copy file
      final currentFile = File(sourcePath);
      await currentFile.copy(uniquePath);

      // 6. Scan media to make it visible in Android
      if (Platform.isAndroid) {
        try {
          await MediaScanner.loadMedia(path: uniquePath);
        } catch (e) {
          debugPrint('Media scan error: $e');
        }
      }

      return uniquePath;
    } catch (e) {
      rethrow;
    }
  }
}
