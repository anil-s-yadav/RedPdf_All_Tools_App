import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:redpdf_tools/theme/app_theme.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'processing_screen.dart';

class AddPagesPdfScreen extends StatefulWidget {
  const AddPagesPdfScreen({super.key});

  @override
  State<AddPagesPdfScreen> createState() => _AddPagesPdfScreenState();
}

class _AddPagesPdfScreenState extends State<AddPagesPdfScreen> {
  File? _basePdf;
  final List<File> _appendPdfs = [];

  Future<void> _pickBasePdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _basePdf = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickAppendPdfs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (file.path != null) {
            _appendPdfs.add(File(file.path!));
          }
        }
      });
    }
  }

  void _removeAppendFile(int index) {
    setState(() {
      _appendPdfs.removeAt(index);
    });
  }

  Future<void> _startAddingPages() async {
    if (_basePdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the original PDF')),
      );
      return;
    }
    if (_appendPdfs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 PDF to append')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          title: 'Adding Pages...',
          task: () async {
            final paths = [_basePdf!.path, ..._appendPdfs.map((f) => f.path)];
            final outPath = await PdfManipulator().mergePDFs(
              params: PDFMergerParams(pdfsPaths: paths),
            );
            if (outPath == null) throw Exception('Add pages failed');
            final file = File(outPath);
            return ProcessResult(
              operation: 'Add Pages',
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
        title: Text('Add Pages to PDF', style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold)),
        backgroundColor: appColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: appColors.text),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('1. Original PDF', style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  if (_basePdf == null)
                    InkWell(
                      onTap: _pickBasePdf,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: appColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: appColors.primary ?? Colors.blue, style: BorderStyle.solid),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_box, color: appColors.primary),
                              const SizedBox(height: 8),
                              Text('Select Original PDF', style: TextStyle(color: appColors.primary)),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      color: appColors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: appColors.primary ?? Colors.blue, width: 2),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.picture_as_pdf, color: appColors.primary, size: 36),
                        title: Text(
                          p.basename(_basePdf!.path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: _pickBasePdf,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  Text('2. Files to Append', style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  
                  ...List.generate(_appendPdfs.length, (index) {
                    final file = _appendPdfs[index];
                    return Card(
                      color: appColors.surface,
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: appColors.divider ?? Colors.transparent),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.note_add, color: Colors.green),
                        title: Text(
                          p.basename(file.path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: appColors.text),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                          onPressed: () => _removeAppendFile(index),
                        ),
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickAppendPdfs,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Add PDFs to append', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
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
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _basePdf != null && _appendPdfs.isNotEmpty ? _startAddingPages : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.green.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Combine Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
