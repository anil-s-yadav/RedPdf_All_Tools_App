import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:redpdf_tools/models/pdf_history.dart';

class PdfProvider with ChangeNotifier {
  List<PdfHistory> _history = [];
  List<PdfHistory> _allFiles = [];
  bool _isLoading = true;
  bool _isScanning = false;
  String _searchQuery = '';

  List<PdfHistory> get history {
    if (_searchQuery.isEmpty) return _history;
    return _history
        .where(
          (file) =>
              file.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  List<PdfHistory> get allFiles {
    if (_searchQuery.isEmpty) return _allFiles;
    return _allFiles
        .where(
          (file) =>
              file.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  PdfProvider() {
    _loadHistory();
    scanAllPdfs();
  }

  Future<void> scanAllPdfs() async {
    _isScanning = true;
    notifyListeners();

    try {
      // 1. Check Permissions
      if (Platform.isAndroid) {
        if (!await Permission.manageExternalStorage.isGranted &&
            !await Permission.storage.isGranted) {
          _isScanning = false;
          notifyListeners();
          return;
        }
      }

      final List<PdfHistory> foundFiles = [];
      final Set<String> pathsSeen = {};
      final List<Directory> scanDirs = [];

      // App's own documents (Fastest access)
      final appDocDir = await getApplicationDocumentsDirectory();
      scanDirs.add(appDocDir);

      if (Platform.isAndroid) {
        // Targeted scan of high-probability folders first (Fast)
        final List<String> commonPaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Documents',
          '/storage/emulated/0/DCIM',
          '/storage/emulated/0/Android/media',
        ];

        for (final path in commonPaths) {
          final dir = Directory(path);
          if (await dir.exists()) {
            scanDirs.add(dir);
          }
        }

        // Root directory as fallback (Slow)
        final rootDir = Directory('/storage/emulated/0');
        if (await rootDir.exists() && !scanDirs.contains(rootDir)) {
          scanDirs.add(rootDir);
        }
      } else if (Platform.isIOS) {
        final appSupportDir = await getApplicationSupportDirectory();
        scanDirs.add(appSupportDir);
      }

      for (final directory in scanDirs) {
        if (await directory.exists()) {
          try {
            // Use recursive: false for the root storage to avoid hanging,
            // but use recursive: true for specific subfolders.
            final bool shouldBeRecursive =
                directory.path != '/storage/emulated/0';

            final Stream<FileSystemEntity> stream = directory.list(
              recursive: shouldBeRecursive,
              followLinks: false,
            );

            await for (var entity in stream) {
              if (entity is File &&
                  entity.path.toLowerCase().endsWith('.pdf') &&
                  !pathsSeen.contains(entity.path)) {
                final pathParts = entity.path.split(Platform.pathSeparator);
                // Basic filter to avoid junk
                if (pathParts.any(
                  (part) =>
                      part.startsWith('.') || part == 'cache' || part == 'temp',
                )) {
                  continue;
                }

                try {
                  final stat = await entity.stat();
                  pathsSeen.add(entity.path);
                  foundFiles.add(
                    PdfHistory(
                      id: entity.path,
                      title: pathParts.last,
                      path: entity.path,
                      sizeInBytes: stat.size,
                      createdAt: stat.changed,
                    ),
                  );
                } catch (_) {}
              }
            }
          } catch (e) {
            debugPrint('Error listing ${directory.path}: $e');
          }
        }
      }

      _allFiles = foundFiles;
      _allFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error scanning PDFs: $e');
    }

    _isScanning = false;
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('pdf_history');
    if (historyJson != null) {
      final List<dynamic> decoded = json.decode(historyJson);
      _history = decoded.map((item) => PdfHistory.fromJson(item)).toList();
    }
    // sort by date descending
    _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(
      _history.map((h) => h.toJson()).toList(),
    );
    await prefs.setString('pdf_history', encoded);
  }

  Future<void> addHistory(PdfHistory newHistory) async {
    _history.insert(0, newHistory);
    notifyListeners();
    await _saveHistory();
  }

  Future<void> removeHistory(String id) async {
    _history.removeWhere((item) => item.id == id);
    notifyListeners();
    await _saveHistory();
  }

  Future<void> clearAllHistory() async {
    _history.clear();
    notifyListeners();
    await _saveHistory();
  }
}
