import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

class PdfFileThumbnail extends StatefulWidget {
  final File file;

  const PdfFileThumbnail({super.key, required this.file});

  @override
  State<PdfFileThumbnail> createState() => _PdfFileThumbnailState();
}

class _PdfFileThumbnailState extends State<PdfFileThumbnail> {
  Uint8List? _imageData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _renderPage();
  }

  @override
  void didUpdateWidget(covariant PdfFileThumbnail oldWidget) {
    if (oldWidget.file.path != widget.file.path) {
      _renderPage();
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> _renderPage() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final doc = await pdfx.PdfDocument.openFile(widget.file.path);
      final page = await doc.getPage(1);
      
      final pageImage = await page.render(
        width: page.width / 4,
        height: page.height / 4,
        format: pdfx.PdfPageImageFormat.jpeg,
      );
      
      if (mounted) {
        setState(() {
          _imageData = pageImage?.bytes;
          _isLoading = false;
        });
      }
      await page.close();
      await doc.close();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_imageData != null) {
      return Image.memory(
        _imageData!,
        fit: BoxFit.cover,
      );
    }
    return const Center(child: Icon(Icons.picture_as_pdf, color: Colors.grey, size: 40));
  }
}
