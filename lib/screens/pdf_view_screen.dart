import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:redpdf_tools/theme/app_theme.dart';

class PdfViewScreen extends StatelessWidget {
  final String path;
  final String title;

  const PdfViewScreen({super.key, required this.path, required this.title});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).appColors;
    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: appColors.text,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appColors.background,
        iconTheme: IconThemeData(color: appColors.text),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: appColors.primary),
            onPressed: () {
              Share.shareXFiles([XFile(path)], text: 'Check out this PDF!');
            },
          ),
        ],
      ),
      body: SfPdfViewer.file(File(path), enableDoubleTapZooming: true),
    );
  }
}
