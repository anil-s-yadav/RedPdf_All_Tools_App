import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:saf/saf.dart';

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

  /// Saves a file to the chosen destination or Downloads/RedPdf folder.
  /// Returns the path or URI of the saved file if successful.
  static Future<String?> saveToDevice({
    required String sourcePath,
    required String fileName,
    String? storageLocation,
  }) async {
    try {
      // 1. If custom SAF content URI is specified
      if (storageLocation != null && storageLocation.startsWith('content://')) {
        String cleanFileName = fileName;
        if (!cleanFileName.toLowerCase().endsWith('.pdf')) {
          cleanFileName += '.pdf';
        }
        final doc = await Saf().pasteLocalFile(
          sourcePath,
          storageLocation,
          cleanFileName,
          'application/pdf',
        );
        return doc.uri;
      }

      // 2. If a custom local directory path is specified
      if (storageLocation != null && storageLocation.trim().isNotEmpty) {
        final customDir = Directory(storageLocation);
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
        }
        final uniquePath = await getUniqueFilePath(customDir.path, fileName);
        final currentFile = File(sourcePath);
        await currentFile.copy(uniquePath);
        if (Platform.isAndroid) {
          try {
            await MediaScanner.loadMedia(path: uniquePath);
          } catch (e) {
            debugPrint('Media scan error: $e');
          }
        }
        return uniquePath;
      }

      // 3. Fallback to default Downloads/RedPdf
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

      Future<String> performSave() async {
        final redPdfDir = Directory('$downloadsPath/RedPdf');
        if (!await redPdfDir.exists()) {
          await redPdfDir.create(recursive: true);
        }

        final uniquePath = await getUniqueFilePath(redPdfDir.path, fileName);
        final currentFile = File(sourcePath);
        await currentFile.copy(uniquePath);

        if (Platform.isAndroid) {
          try {
            await MediaScanner.loadMedia(path: uniquePath);
          } catch (e) {
            debugPrint('Media scan error: $e');
          }
        }
        return uniquePath;
      }

      try {
        // Try saving directly first. Android 11+ allows writing to Downloads without permissions.
        return await performSave();
      } catch (e) {
        if (Platform.isAndroid) {
          // Fallback for older Android versions (Android 10 and below)
          final status = await Permission.storage.request();
          if (status.isGranted) {
            return await performSave();
          } else {
            // Last resort
            final manageStatus = await Permission.manageExternalStorage.request();
            if (manageStatus.isGranted) {
              return await performSave();
            } else {
              throw Exception('Storage permission denied');
            }
          }
        } else {
          rethrow;
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
