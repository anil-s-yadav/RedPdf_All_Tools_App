import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PdfPageSize { a4, letter, a3, legal }

enum PdfPageOrientation { portrait, landscape }

class SettingsProvider with ChangeNotifier {
  static const _storageKey = 'storage_location';

  PdfPageSize _defaultPageSize = PdfPageSize.a4;
  PdfPageOrientation _defaultOrientation = PdfPageOrientation.portrait;
  String _storageLocation = '';

  PdfPageSize get defaultPageSize => _defaultPageSize;
  PdfPageOrientation get defaultOrientation => _defaultOrientation;
  String get storageLocation => _storageLocation;

  String get storageLocationDisplay {
    if (_storageLocation.isEmpty) {
      return 'Download/RedPdf';
    }
    if (_storageLocation.startsWith('content://')) {
      if (_storageLocation.contains('%3A')) {
        return Uri.decodeComponent(_storageLocation.split('%3A').last);
      }
      final decoded = Uri.decodeComponent(_storageLocation);
      if (decoded.contains(':')) {
        return decoded.split(':').last;
      }
      return decoded;
    }
    return _storageLocation.replaceAll('/storage/emulated/0/', '');
  }

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultPageSize = PdfPageSize.values[prefs.getInt('defaultPageSize') ?? 0];
    _defaultOrientation =
        PdfPageOrientation.values[prefs.getInt('defaultOrientation') ?? 0];
    _storageLocation = prefs.getString(_storageKey) ?? '';
    notifyListeners();
  }

  Future<void> setStorageLocation(String path) async {
    _storageLocation = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, path);
  }

  Future<void> resetStorageLocation() async {
    _storageLocation = '';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> setDefaultPageSize(PdfPageSize size) async {
    _defaultPageSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('defaultPageSize', size.index);
    notifyListeners();
  }

  Future<void> setDefaultOrientation(PdfPageOrientation orientation) async {
    _defaultOrientation = orientation;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('defaultOrientation', orientation.index);
    notifyListeners();
  }

  // Helper strings for UI
  String get pageSizeString {
    switch (_defaultPageSize) {
      case PdfPageSize.a4:
        return 'A4';
      case PdfPageSize.letter:
        return 'Letter';
      case PdfPageSize.a3:
        return 'A3';
      case PdfPageSize.legal:
        return 'Legal';
    }
  }

  String get orientationString {
    switch (_defaultOrientation) {
      case PdfPageOrientation.portrait:
        return 'Portrait';
      case PdfPageOrientation.landscape:
        return 'Landscape';
    }
  }
}
