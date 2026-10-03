import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:redpdf_tools/theme/app_theme.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'processing_screen.dart';

class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  File? _selectedPdf;
  int _pageCount = 0;
  bool _isLoading = false;
  final TextEditingController _rangesController = TextEditingController();

  @override
  void dispose() {
    _rangesController.dispose();
    super.dispose();
  }

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
          _rangesController.text = '1-$count';
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

  Future<void> _startSplitting() async {
    final text = _rangesController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter split ranges')),
      );
      return;
    }

    // Basic validation of format: 1-2, 3-4, 5
    final parts = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          title: 'Splitting PDF...',
          task: () async {
            final paths = await PdfManipulator().splitPDF(
              params: PDFSplitterParams(
                pdfPath: _selectedPdf!.path,
                pageRanges: parts,
              ),
            );
            if (paths == null || paths.isEmpty) throw Exception('Split failed');
            final outPath = paths.first;
            final file = File(outPath);
            return ProcessResult(
              operation: 'Split PDF',
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
        title: Text('Split PDF', style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold)),
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
                              Icon(Icons.call_split, size: 80, color: appColors.subtitle?.withValues(alpha: 0.2)),
                              const SizedBox(height: 16),
                              Text(
                                'Select a PDF to split',
                                style: TextStyle(color: appColors.subtitle, fontSize: 18),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: appColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: appColors.divider ?? Colors.transparent),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.picture_as_pdf, color: appColors.primary, size: 40),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.basename(_selectedPdf!.path),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
                                          Text('$_pageCount pages', style: TextStyle(color: appColors.subtitle)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'Enter Page Ranges',
                                style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _rangesController,
                                style: TextStyle(color: appColors.text),
                                decoration: InputDecoration(
                                  hintText: 'e.g., 1-5, 6-10',
                                  hintStyle: TextStyle(color: appColors.subtitle?.withValues(alpha: 0.5)),
                                  filled: true,
                                  fillColor: appColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: appColors.divider ?? Colors.transparent),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: appColors.divider ?? Colors.transparent),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Use commas to separate multiple ranges or individual pages (e.g., 1-3, 5, 8-12). Each range will become a separate PDF file.',
                                style: TextStyle(color: appColors.subtitle, fontSize: 12),
                              ),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ActionChip(
                                    label: const Text('Split every page'),
                                    onPressed: () {
                                      final ranges = List.generate(_pageCount, (i) => '${i + 1}').join(', ');
                                      _rangesController.text = ranges;
                                    },
                                    backgroundColor: appColors.primary?.withValues(alpha: 0.1),
                                    labelStyle: TextStyle(color: appColors.primary),
                                  ),
                                  ActionChip(
                                    label: const Text('Split in half'),
                                    onPressed: () {
                                      if (_pageCount > 1) {
                                        final half = _pageCount ~/ 2;
                                        _rangesController.text = '1-$half, ${half + 1}-$_pageCount';
                                      }
                                    },
                                    backgroundColor: appColors.primary?.withValues(alpha: 0.1),
                                    labelStyle: TextStyle(color: appColors.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                    if (_selectedPdf != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _startSplitting,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Split PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
