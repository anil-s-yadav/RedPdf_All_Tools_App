import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:redpdf_tools/theme/app_theme.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'processing_screen.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final List<File> _selectedPdfs = [];

  Future<void> _pickPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (file.path != null) {
            _selectedPdfs.add(File(file.path!));
          }
        }
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedPdfs.removeAt(index);
    });
  }

  void _reorderFiles(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final file = _selectedPdfs.removeAt(oldIndex);
      _selectedPdfs.insert(newIndex, file);
    });
  }

  Future<void> _startMerging() async {
    if (_selectedPdfs.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 2 PDFs to merge')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          title: 'Merging PDFs...',
          task: () async {
            final paths = _selectedPdfs.map((f) => f.path).toList();
            final outPath = await PdfManipulator().mergePDFs(
              params: PDFMergerParams(pdfsPaths: paths),
            );
            if (outPath == null) throw Exception('Merge failed');
            final file = File(outPath);
            return ProcessResult(
              operation: 'Merge PDFs',
              filePath: outPath,
              fileName: p.basename(outPath),
              fileSize: await file.length(),
              totalPages: 0,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        title: Text('Merge PDFs', style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: appColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: appColors.text),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _selectedPdfs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.merge_type, size: 80, color: appColors.subtitle?.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'No PDFs Selected',
                            style: TextStyle(color: appColors.subtitle, fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _selectedPdfs.length,
                      onReorderItem: _reorderFiles,
                      itemBuilder: (context, index) {
                        final file = _selectedPdfs[index];
                        return Card(
                          key: ValueKey(file.path),
                          color: appColors.surface,
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: appColors.divider ?? Colors.transparent),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.picture_as_pdf, color: appColors.primary),
                            title: Text(
                              p.basename(file.path),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: appColors.text),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.redAccent),
                              onPressed: () => _removeFile(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: appColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _pickPdfs,
                        icon: const Icon(Icons.add),
                        label: const Text('Add PDFs'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors.primary?.withValues(alpha: 0.1),
                          foregroundColor: appColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    if (_selectedPdfs.length >= 2) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _startMerging,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Merge PDFs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
