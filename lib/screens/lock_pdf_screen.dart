import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:redpdf_tools/providers/pdf_provider.dart';
import 'package:redpdf_tools/theme/app_theme.dart';
import 'processing_screen.dart';
import '../utils/file_utils.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:redpdf_tools/models/pdf_history.dart';

class LockPdfScreen extends StatefulWidget {
  const LockPdfScreen({super.key});

  @override
  State<LockPdfScreen> createState() => _LockPdfScreenState();
}

class _LockPdfScreenState extends State<LockPdfScreen> {
  File? _selectedPdf;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPdf = File(result.files.single.path!);
      });
    }
  }

  Future<ProcessResult> _lockPdfTask() async {
    if (_selectedPdf == null || _passwordController.text.isEmpty) {
      throw Exception("No PDF selected or password empty");
    }

    final documentBytes = await _selectedPdf!.readAsBytes();
    final document = PdfDocument(inputBytes: documentBytes);

    // Apply Security
    final security = document.security;
    security.userPassword = _passwordController.text;
    security.ownerPassword = _passwordController.text;

    final bytes = await document.save();
    final pageCount = document.pages.count;
    document.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final originalName = _selectedPdf!.path.split(Platform.pathSeparator).last;
    final fileName = 'Locked_$originalName';

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
      operation: "Locked",
      filePath: newFile.path,
      fileName: finalFileName,
      fileSize: bytes.length,
      totalPages: pageCount,
      password: _passwordController.text,
    );
  }

  void _startProcessing() {
    if (_selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PDF first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm your password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProcessingScreen(title: 'Locking PDF...', task: _lockPdfTask),
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
          'Lock PDF',
          style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold),
        ),
        backgroundColor: appColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: appColors.text),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(
                child: ElevatedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Select PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors.primary!.withValues(alpha: 0.1),
                    foregroundColor: appColors.primary,
                    elevation: 0,
                  ),
                ),
              ),
              if (_selectedPdf != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Selected: ${_selectedPdf!.path.split(Platform.pathSeparator).last}',
                  style: TextStyle(color: appColors.text),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Create a password",
                    style: TextStyle(
                      color: appColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  style: TextStyle(color: appColors.text),
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter password',
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
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  style: TextStyle(color: appColors.text),
                  obscureText: _obscureConfirmPassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter password',
                    errorText: (_confirmPasswordController.text.isNotEmpty &&
                            _passwordController.text !=
                                _confirmPasswordController.text)
                        ? 'Passwords do not match'
                        : null,
                    labelStyle: TextStyle(color: appColors.subtitle),
                    hintStyle: TextStyle(
                      color: appColors.subtitle?.withValues(alpha: 0.6),
                    ),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                        () => _obscureConfirmPassword =
                            !_obscureConfirmPassword,
                      ),
                      icon: Icon(
                        _obscureConfirmPassword
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
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Lock PDF'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
