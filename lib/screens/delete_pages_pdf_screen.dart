import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:redpdf_tools/theme/app_theme.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'processing_screen.dart';

class DeletePagesPdfScreen extends StatefulWidget {
  const DeletePagesPdfScreen({super.key});

  @override
  State<DeletePagesPdfScreen> createState() => _DeletePagesPdfScreenState();
}

class _DeletePagesPdfScreenState extends State<DeletePagesPdfScreen> {
  File? _selectedPdf;
  int _pageCount = 0;
  final Set<int> _pagesToDelete = {};
  bool _isLoading = false;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _isLoading = true;
      });
      final file = File(result.files.single.path!);
      try {
        final bytes = await file.readAsBytes();
        final doc = PdfDocument(inputBytes: bytes);
        final count = doc.pages.count;
        doc.dispose();
        setState(() {
          _selectedPdf = file;
          _pageCount = count;
          _pagesToDelete.clear();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot read this PDF. It may be encrypted or corrupted.')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _togglePage(int page) {
    setState(() {
      if (_pagesToDelete.contains(page)) {
        _pagesToDelete.remove(page);
      } else {
        _pagesToDelete.add(page);
      }
    });
  }

  Future<void> _startDeleting() async {
    if (_pagesToDelete.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 page to delete')),
      );
      return;
    }
    if (_pagesToDelete.length == _pageCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete all pages')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          title: 'Deleting Pages...',
          task: () async {
            final outPath = await PdfManipulator().pdfPageDeleter(
              params: PDFPageDeleterParams(
                pdfPath: _selectedPdf!.path,
                pageNumbers: _pagesToDelete.toList()..sort(),
              ),
            );
            if (outPath == null) throw Exception('Delete failed');
            final file = File(outPath);
            return ProcessResult(
              operation: 'Delete Pages',
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
        title: Text('Delete PDF Pages', style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: appColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: appColors.text),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedPdf == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_delete_outlined, size: 80, color: appColors.subtitle?.withValues(alpha: 0.2)),
                              const SizedBox(height: 16),
                              Text(
                                'Select a PDF to delete pages',
                                style: TextStyle(color: appColors.subtitle, fontSize: 18),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Icon(Icons.picture_as_pdf, color: appColors.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      p.basename(_selectedPdf!.path),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    '$_pageCount pages',
                                    style: TextStyle(color: appColors.subtitle),
                                  ),
                                ],
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Tap pages you want to DELETE:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.all(20),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 1,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: _pageCount,
                                itemBuilder: (context, index) {
                                  final page = index + 1;
                                  final isSelected = _pagesToDelete.contains(page);
                                  return GestureDetector(
                                    onTap: () => _togglePage(page),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.redAccent.withValues(alpha: 0.1) : appColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? Colors.redAccent : (appColors.divider ?? Colors.transparent),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$page',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.redAccent : appColors.text,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
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
                        onPressed: _pickPdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(_selectedPdf == null ? 'Select PDF' : 'Change PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors.primary?.withValues(alpha: 0.1),
                          foregroundColor: appColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    if (_selectedPdf != null && _pagesToDelete.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _startDeleting,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Delete ${_pagesToDelete.length} Pages', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
