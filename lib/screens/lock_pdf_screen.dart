import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:redpdf_tools/providers/pdf_provider.dart';
import 'package:redpdf_tools/theme/app_theme.dart';
import 'success_screen.dart';
import '../utils/file_utils.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:redpdf_tools/models/pdf_history.dart';
import 'package:uuid/uuid.dart';

class LockPdfScreen extends StatefulWidget {
  const LockPdfScreen({super.key});

  @override
  State<LockPdfScreen> createState() => _LockPdfScreenState();
}

class _LockPdfScreenState extends State<LockPdfScreen> {
  File? _selectedPdf;
  final TextEditingController _passwordController = TextEditingController();
  bool _isProcessing = false;
  bool isVisible = true;

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

  Future<void> _lockPdf() async {
    if (_selectedPdf == null || _passwordController.text.isEmpty) return;

    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final canProceed = await authProvider.checkAndIncrementLimit();

    // if (!mounted) return;

    // if (!canProceed) {
    //   showLimitReachedDialog(context, authProvider.isAuthenticated);
    //   return;
    // }

    setState(() => _isProcessing = true);

    try {
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
      final originalName = _selectedPdf!.path
          .split(Platform.pathSeparator)
          .last;
      final fileName = 'Locked_$originalName';

      final uniquePath = await FileUtils.getUniqueFilePath(dir.path, fileName);
      final newFile = File(uniquePath);
      final finalFileName = p.basename(uniquePath);

      await newFile.writeAsBytes(bytes);

      // Save to history
      final history = PdfHistory(
        id: Uuid().v4(),
        title: finalFileName,
        path: newFile.path,
        sizeInBytes: bytes.length,
        createdAt: DateTime.now(),
      );

      if (!mounted) return;
      context.read<PdfProvider>().addHistory(history);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            operation: "Locked",
            filePath: newFile.path,
            fileName: finalFileName,
            fileSize: bytes.length,
            totalPages: pageCount,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Lock PDF error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to lock PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _isProcessing = false);
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
                    backgroundColor: appColors.primary!.withOpacity(0.1),
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
                Text(
                  "Create a password!",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _passwordController,
                  style: TextStyle(color: appColors.text),

                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: appColors.subtitle),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => isVisible = !isVisible),
                      icon: isVisible
                          ? Icon(Icons.visibility)
                          : Icon(Icons.visibility_off),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: appColors.divider ?? Colors.grey,
                      ),
                    ),
                  ),
                  obscureText: isVisible,
                ),
                const SizedBox(height: 24),
                _isProcessing
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _lockPdf,
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
