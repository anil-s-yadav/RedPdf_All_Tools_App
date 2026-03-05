import 'dart:io';
import 'package:flutter/material.dart';
import 'package:redpdf_tools/screens/pdf_view_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:redpdf_tools/theme/app_theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../utils/file_utils.dart';
import 'package:path/path.dart' as p;

class SuccessScreen extends StatelessWidget {
  final String operation;
  final String filePath;
  final String fileName;
  final int fileSize;
  final int totalPages;

  const SuccessScreen({
    super.key,
    required this.operation,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.totalPages,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _sharePdf() {
    Share.shareXFiles([XFile(filePath)], text: 'Check out my document!');
  }

  void _openPdf(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewScreen(path: filePath, title: fileName),
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> _saveToDownloads(BuildContext context) async {
    try {
      final savedPath = await FileUtils.saveToDevice(
        sourcePath: filePath,
        fileName: fileName,
      );

      if (savedPath != null) {
        final finalFileName = p.basename(savedPath);
        // 7. Success message
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Download/RedPdf/$finalFileName'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            persist: true,
            showCloseIcon: true,
          ),
        );
      }
    } catch (e) {
      debugPrint('Save to device error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).appColors;
    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        backgroundColor: appColors.background,
        elevation: 0,
        title: Text(
          'Success',
          style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: appColors.text),
        actions: [
          TextButton(
            onPressed: () => _goHome(context),
            child: Text(
              'Done',
              style: TextStyle(
                color: appColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'PDF $operation Successfully!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: appColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your document has been processed\nand is ready for use.',
                style: TextStyle(
                  fontSize: 16,
                  color: appColors.subtitle,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: appColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: appColors.divider ?? Colors.transparent,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: appColors.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatSize(fileSize)} • $totalPages Pages',
                                style: TextStyle(
                                  color: appColors.subtitle,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: appColors.primary!.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.picture_as_pdf,
                            color: appColors.primary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color:
                            appColors.divider?.withOpacity(0.1) ??
                            Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: appColors.divider ?? Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AbsorbPointer(
                          // Prevent scrolling/interaction, just show the first part
                          child: SfPdfViewer.file(
                            File(filePath),
                            canShowScrollHead: false,
                            canShowScrollStatus: false,
                            enableDoubleTapZooming: false,
                            enableTextSelection: false,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _sharePdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text(
                    'Share PDF',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: TextButton.icon(
                        onPressed: () => _openPdf(context),
                        style: TextButton.styleFrom(
                          backgroundColor: appColors.primary!.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        icon: Icon(Icons.open_in_new, color: appColors.primary),
                        label: Text(
                          'Open',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: appColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: TextButton.icon(
                        onPressed: () => _saveToDownloads(context),
                        style: TextButton.styleFrom(
                          backgroundColor: appColors.primary!.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        icon: Icon(Icons.download, color: appColors.primary),
                        label: Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: appColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: () => _goHome(context),
                icon: Icon(Icons.home, color: appColors.subtitle),
                label: Text(
                  'Back to Home',
                  style: TextStyle(color: appColors.subtitle, fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
