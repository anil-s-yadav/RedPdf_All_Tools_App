import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:redpdf_tools/theme/app_theme.dart';
import 'package:redpdf_tools/utils/file_utils.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as spdf;
import 'package:path_provider/path_provider.dart';
import 'processing_screen.dart';
import '../widgets/pdf_file_thumbnail.dart';
import 'pdf_view_screen.dart';

class AddPagesPdfScreen extends StatefulWidget {
  const AddPagesPdfScreen({super.key});

  @override
  State<AddPagesPdfScreen> createState() => _AddPagesPdfScreenState();
}

class _AddPagesPdfScreenState extends State<AddPagesPdfScreen> {
  File? _basePdf;
  final List<File> _appendImages = [];

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

  Future<void> _pickAppendImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (file.path != null) {
            _appendImages.add(File(file.path!));
          }
        }
      });
    }
  }

  void _removeAppendImage(int index) {
    setState(() {
      _appendImages.removeAt(index);
    });
  }

  Future<void> _startAddingPages() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          title: 'Adding Pages...',
          task: () async {
            // 1. Convert Images to a temporary PDF
            final document = spdf.PdfDocument();
            document.pageSettings.size = spdf.PdfPageSize.a4;
            document.pageSettings.margins.all = 0;

            for (var imageFile in _appendImages) {
              final imageBytes = await imageFile.readAsBytes();
              final spdf.PdfBitmap image = spdf.PdfBitmap(imageBytes);

              final spdf.PdfPage page = document.pages.add();

              final double imgWidth = image.width.toDouble();
              final double imgHeight = image.height.toDouble();
              final double pageWidth = page.getClientSize().width;
              final double pageHeight = page.getClientSize().height;

              double drawWidth = pageWidth;
              double drawHeight = (imgHeight / imgWidth) * pageWidth;

              if (drawHeight > pageHeight) {
                drawHeight = pageHeight;
                drawWidth = (imgWidth / imgHeight) * pageHeight;
              }

              final double x = (pageWidth - drawWidth) / 2;
              final double y = (pageHeight - drawHeight) / 2;

              page.graphics.drawImage(
                image,
                Rect.fromLTWH(x, y, drawWidth, drawHeight),
              );
            }

            final List<int> bytesList = document.saveSync();
            document.dispose();

            final tempDir = await getTemporaryDirectory();
            final tempPdfPath = p.join(
              tempDir.path,
              'temp_append_${DateTime.now().millisecondsSinceEpoch}.pdf',
            );
            await File(tempPdfPath).writeAsBytes(bytesList);

            // 2. Merge original PDF with the new temporary PDF
            final paths = [_basePdf!.path, tempPdfPath];
            final outPath = await PdfManipulator().mergePDFs(
              params: PDFMergerParams(pdfsPaths: paths),
            );
            if (outPath == null) throw Exception('Add pages failed');

            final file = File(outPath);
            final newPath = p.join(
              file.parent.path,
              '${FileUtils.generateDefaultFileName(prefix: 'Appended')}.pdf',
            );
            final renamedFile = await file.rename(newPath);

            return ProcessResult(
              operation: 'Add Pages',
              filePath: renamedFile.path,
              fileName: p.basename(renamedFile.path),
              fileSize: await renamedFile.length(),
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
        title: Text(
          'Add Pages to PDF',
          style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold),
        ),
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
                  Text(
                    '1. Original PDF',
                    style: TextStyle(
                      color: appColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_basePdf == null)
                    InkWell(
                      onTap: _pickBasePdf,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: appColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: appColors.primary ?? Colors.blue,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_box, color: appColors.primary),
                              const SizedBox(height: 8),
                              Text(
                                'Select Original PDF',
                                style: TextStyle(color: appColors.primary),
                              ),
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
                        side: BorderSide(
                          color: appColors.primary ?? Colors.blue,
                          width: 2,
                        ),
                      ),
                      child: ListTile(
                        leading: SizedBox(
                          width: 40,
                          height: 55,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: PdfFileThumbnail(file: _basePdf!),
                          ),
                        ),
                        title: Text(
                          p.basename(_basePdf!.path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: appColors.text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: _pickBasePdf,
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  Text(
                    '2. Images to Add as Pages',
                    style: TextStyle(
                      color: appColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...List.generate(_appendImages.length, (index) {
                    final file = _appendImages[index];
                    return Card(
                      color: appColors.surface,
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: appColors.divider ?? Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        leading: SizedBox(
                          width: 40,
                          height: 55,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(file, fit: BoxFit.cover),
                          ),
                        ),
                        title: Text(
                          p.basename(file.path),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: appColors.text),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _removeAppendImage(index),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickAppendImages,
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
                            Icon(
                              Icons.add_photo_alternate,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Select Images',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                    onPressed: _basePdf != null && _appendImages.isNotEmpty
                        ? _startAddingPages
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.green.withValues(
                        alpha: 0.3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Merge into PDF',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
