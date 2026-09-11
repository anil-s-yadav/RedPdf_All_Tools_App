import 'package:flutter/material.dart';
import 'package:redpdf_tools/providers/pdf_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:redpdf_tools/theme/app_theme.dart';
import 'processing_screen.dart';
import '../utils/file_utils.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:redpdf_tools/models/pdf_history.dart';

class UnlockPdfScreen extends StatefulWidget {
  final File? initialPdf;
  const UnlockPdfScreen({super.key, this.initialPdf});

  @override
  State<UnlockPdfScreen> createState() => _UnlockPdfScreenState();
}

class _UnlockPdfScreenState extends State<UnlockPdfScreen> {
  File? _selectedPdf;
  int? _selectedBytes;
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialPdf != null) {
      _selectedPdf = widget.initialPdf;
      _loadFileBytes(widget.initialPdf!);
    }
  }

  Future<void> _loadFileBytes(File file) async {
    try {
      final bytes = await file.length();
      if (mounted) setState(() => _selectedBytes = bytes);
    } catch (_) {}
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.length();
      setState(() {
        _selectedPdf = file;
        _selectedBytes = bytes;
      });
    }
  }

  Future<ProcessResult> _unlockPdfTask() async {
    if (_selectedPdf == null || _passwordController.text.isEmpty) {
      throw Exception("No PDF selected or password empty");
    }

    final documentBytes = await _selectedPdf!.readAsBytes();
    final document = PdfDocument(
      inputBytes: documentBytes,
      password: _passwordController.text,
    );

    // Unlocking by removing security block
    final security = document.security;
    security.userPassword = '';
    security.ownerPassword = '';

    final bytes = await document.save();
    final pageCount = document.pages.count;
    document.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final originalName = _selectedPdf!.path.split(Platform.pathSeparator).last;
    final fileName = 'Unlocked_$originalName';

    final uniquePath = await FileUtils.getUniqueFilePath(dir.path, fileName);
    final newFile = File(uniquePath);
    final finalFileName = p.basename(uniquePath);

    await newFile.writeAsBytes(bytes);

    // Save to history
    final history = PdfHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: finalFileName,
      path: newFile.path,
      sizeInBytes: bytes.length,
      createdAt: DateTime.now(),
    );

    if (mounted) {
      context.read<PdfProvider>().addHistory(history);
    }

    return ProcessResult(
      operation: "Unlocked",
      filePath: newFile.path,
      fileName: finalFileName,
      fileSize: bytes.length,
      totalPages: pageCount,
    );
  }

  void _startProcessing() {
    if (_selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a secured PDF first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the password to unlock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProcessingScreen(title: 'Unlocking PDF...', task: _unlockPdfTask),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).appColors;
    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        title: Text(
          'Unlock PDF',
          style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold),
        ),
        backgroundColor: appColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: appColors.text),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFileSection(appColors),
              if (_selectedPdf != null) ...[
                const SizedBox(height: 24),
                Text(
                  "Enter PDF Password",
                  style: TextStyle(
                    color: appColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  style: TextStyle(color: appColors.text),
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter password to unlock',
                    labelStyle: TextStyle(color: appColors.subtitle),
                    hintStyle: TextStyle(
                      color: appColors.subtitle?.withValues(alpha: 0.6),
                    ),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: appColors.subtitle,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: appColors.divider ?? Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _startProcessing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Unlock PDF'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileSection(AppColors appColors) {
    if (_selectedPdf == null) {
      return GestureDetector(
        onTap: _pickPdf,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            color: appColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.teal.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 40,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Select PDF to Unlock',
                style: TextStyle(
                  color: appColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap to browse files from device',
                style: TextStyle(
                  color: appColors.subtitle,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fileName = _selectedPdf!.path.split(Platform.pathSeparator).last;
    final sizeStr = _selectedBytes != null ? _formatBytes(_selectedBytes!) : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: appColors.divider ?? Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.teal,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    color: appColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: $sizeStr',
                  style: TextStyle(
                    color: appColors.subtitle,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _pickPdf,
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal,
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
