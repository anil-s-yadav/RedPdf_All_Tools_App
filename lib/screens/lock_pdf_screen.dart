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
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'unlock_pdf_screen.dart';

class LockPdfScreen extends StatefulWidget {
  const LockPdfScreen({super.key});

  @override
  State<LockPdfScreen> createState() => _LockPdfScreenState();
}

class _LockPdfScreenState extends State<LockPdfScreen> {
  File? _selectedPdf;
  int? _selectedBytes;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isVerifying = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<bool> _isPdfLocked(File file) async {
    // 1. Primary check using PdfManipulator (native QPDF)
    try {
      final protectionInfo = await PdfManipulator().pdfValidityAndProtection(
        params: PDFValidityAndProtectionParams(pdfPath: file.path),
      );
      if (protectionInfo != null &&
          (protectionInfo.isOpenPasswordProtected == true ||
              protectionInfo.isOwnerPasswordProtected == true)) {
        return true;
      }
    } catch (_) {}

    // 2. Fallback check using Syncfusion PdfDocument
    try {
      final documentBytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: documentBytes);
      final isProtected = document.security.userPassword.isNotEmpty ||
          document.security.ownerPassword.isNotEmpty;
      document.dispose();
      if (isProtected) return true;
    } catch (e) {
      final err = e.toString().toLowerCase();
      if (err.contains('password') ||
          err.contains('encrypt') ||
          err.contains('security') ||
          err.contains('protected')) {
        return true;
      }
    }

    return false;
  }

  void _showAlreadyLockedDialog(File file) {
    final fileName = p.basename(file.path);
    final appColors = Theme.of(context).appColors;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: appColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: Colors.amber,
            size: 36,
          ),
        ),
        title: Text(
          'PDF Already Locked',
          style: TextStyle(
            color: appColors.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This PDF already has a password on it.',
              style: TextStyle(
                color: appColors.text,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"$fileName" is already password-protected. You cannot lock a PDF that is already locked.\n\nIf you wish to change or remove its password, please unlock it first.',
              style: TextStyle(
                color: appColors.subtitle ?? Colors.grey[700],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: TextStyle(color: appColors.subtitle),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UnlockPdfScreen(initialPdf: file),
                ),
              );
            },
            icon: const Icon(Icons.lock_open, size: 18),
            label: const Text('Unlock PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This PDF already has a password on it ($fileName).',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.amber.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final pickedFile = File(result.files.single.path!);
      final bytes = await pickedFile.length();

      setState(() {
        _isVerifying = true;
      });

      final isLocked = await _isPdfLocked(pickedFile);

      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      if (isLocked) {
        _showAlreadyLockedDialog(pickedFile);
        return;
      }

      setState(() {
        _selectedPdf = pickedFile;
        _selectedBytes = bytes;
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

  Future<void> _startProcessing() async {
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

    setState(() {
      _isVerifying = true;
    });

    final isLocked = await _isPdfLocked(_selectedPdf!);

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
    });

    if (isLocked) {
      _showAlreadyLockedDialog(_selectedPdf!);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFileSection(appColors),
              if (_selectedPdf != null) ...[
                const SizedBox(height: 24),
                Text(
                  "Create a password",
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
                  onPressed: _isVerifying ? null : _startProcessing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Lock PDF'),
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
        onTap: _isVerifying ? null : _pickPdf,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            color: appColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.redAccent,
                        ),
                      )
                    : const Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 40,
                        color: Colors.redAccent,
                      ),
              ),
              const SizedBox(height: 14),
              Text(
                _isVerifying ? 'Checking PDF...' : 'Select PDF to Lock',
                style: TextStyle(
                  color: appColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isVerifying
                    ? 'Verifying password protection...'
                    : 'Tap to browse files from device',
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
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.redAccent,
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
            onPressed: _isVerifying ? null : _pickPdf,
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
            child: _isVerifying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Change'),
          ),
        ],
      ),
    );
  }
}
