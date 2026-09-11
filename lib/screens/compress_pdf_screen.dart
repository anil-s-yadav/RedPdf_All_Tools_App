import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf_manipulator/pdf_manipulator.dart';
import 'package:redpdf_tools/providers/pdf_provider.dart';
import 'package:redpdf_tools/theme/app_theme.dart';
import 'package:redpdf_tools/models/pdf_history.dart';
import '../utils/file_utils.dart';
import 'processing_screen.dart';
import 'pdf_view_screen.dart';

enum CompressionMode {
  level,
  percentage,
  targetSize,
}

enum CompressionLevel {
  low, // 80% quality, 0.8 scale (High visual quality)
  medium, // 60% quality, 0.6 scale (Recommended / Balanced)
  high, // 35% quality, 0.4 scale (Maximum reduction)
}

class CompressPdfScreen extends StatefulWidget {
  const CompressPdfScreen({super.key});

  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}

class _CompressPdfScreenState extends State<CompressPdfScreen> {
  File? _selectedPdf;
  int? _selectedBytes;
  CompressionMode _mode = CompressionMode.level;
  CompressionLevel _level = CompressionLevel.medium;
  double _compressionPercentage = 50.0;
  final TextEditingController _targetSizeController = TextEditingController();
  String _targetSizeUnit = 'KB';
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void dispose() {
    _fileNameController.dispose();
    _targetSizeController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
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

  Future<String?> _showPasswordDialog(BuildContext context) async {
    final controller = TextEditingController();
    bool obscure = true;
    final appColors = Theme.of(context).appColors;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: appColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_rounded, color: appColors.primary),
              const SizedBox(width: 10),
              Text(
                'Password Protected',
                style: TextStyle(
                  color: appColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This PDF is protected with a password. Please enter the password to compress it.',
                style: TextStyle(color: appColors.subtitle, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                obscureText: obscure,
                style: TextStyle(color: appColors.text),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: appColors.subtitle,
                    ),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text('Cancel', style: TextStyle(color: appColors.subtitle)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Unlock & Compress'),
            ),
          ],
        ),
      ),
    );
  }

  Future<ProcessResult> _compressPdfTask() async {
    if (_selectedPdf == null) {
      throw Exception("No PDF selected");
    }

    final src = _selectedPdf!;
    File fileToCompress = src;
    bool isProtected = false;
    String? userPassword;

    // 1. Check if PDF is encrypted
    try {
      final protectionInfo = await PdfManipulator().pdfValidityAndProtection(
        params: PDFValidityAndProtectionParams(pdfPath: src.path),
      );
      if (protectionInfo != null &&
          (protectionInfo.isOpenPasswordProtected == true ||
              protectionInfo.isOwnerPasswordProtected == true)) {
        isProtected = true;
      }
    } catch (_) {}

    // 2. Decrypt if password-protected
    if (isProtected) {
      if (!mounted) throw Exception("Cancelled");
      userPassword = await _showPasswordDialog(context);
      if (userPassword == null || userPassword.isEmpty) {
        throw Exception("Password is required to compress this PDF.");
      }

      try {
        final unencryptedPath = await PdfManipulator().pdfDecryption(
          params: PDFDecryptionParams(
            pdfPath: src.path,
            password: userPassword,
          ),
        );
        if (unencryptedPath == null) throw Exception("Decryption failed");
        fileToCompress = File(unencryptedPath);
      } catch (e) {
        throw Exception("Incorrect password or decryption failed.");
      }
    }

    // 3. Configure compression quality & scale
    int imageQuality;
    double imageScale;

    switch (_mode) {
      case CompressionMode.level:
        switch (_level) {
          case CompressionLevel.low:
            imageQuality = 80;
            imageScale = 0.8;
            break;
          case CompressionLevel.medium:
            imageQuality = 60;
            imageScale = 0.6;
            break;
          case CompressionLevel.high:
            imageQuality = 35;
            imageScale = 0.4;
            break;
        }
        break;

      case CompressionMode.percentage:
        final pct = _compressionPercentage.clamp(10.0, 90.0);
        imageQuality = (100 - (pct * 0.8)).round().clamp(20, 95);
        imageScale = (1.0 - (pct / 100.0) * 0.7).clamp(0.25, 1.0);
        break;

      case CompressionMode.targetSize:
        final targetVal =
            double.tryParse(_targetSizeController.text.trim()) ?? 0;
        if (targetVal <= 0) {
          throw Exception("Please enter a valid target size.");
        }
        final targetBytes =
            targetVal * (_targetSizeUnit == 'MB' ? 1024 * 1024 : 1024);
        final origBytes = _selectedBytes ?? (await fileToCompress.length());
        final ratio = (targetBytes / origBytes).clamp(0.05, 1.0);

        if (ratio >= 0.85) {
          imageQuality = 80;
          imageScale = 0.85;
        } else if (ratio >= 0.65) {
          imageQuality = 65;
          imageScale = 0.7;
        } else if (ratio >= 0.45) {
          imageQuality = 50;
          imageScale = 0.55;
        } else if (ratio >= 0.25) {
          imageQuality = 35;
          imageScale = 0.4;
        } else {
          imageQuality = (ratio * 100).round().clamp(20, 30);
          imageScale = (ratio * 1.1).clamp(0.25, 0.35);
        }
        break;
    }

    // 4. Run compression using PdfManipulator
    final String? tempCompressedPath = await PdfManipulator().pdfCompressor(
      params: PDFCompressorParams(
        pdfPath: fileToCompress.path,
        imageQuality: imageQuality,
        imageScale: imageScale,
        unEmbedFonts: false,
      ),
    );

    if (tempCompressedPath == null) {
      throw Exception("Compression failed. Please try a different option.");
    }

    File outFile = File(tempCompressedPath);

    // If target size mode, refine if first pass exceeded target
    if (_mode == CompressionMode.targetSize) {
      final targetVal =
          double.tryParse(_targetSizeController.text.trim()) ?? 0;
      if (targetVal > 0) {
        final targetBytes =
            targetVal * (_targetSizeUnit == 'MB' ? 1024 * 1024 : 1024);
        final outLen = await outFile.length();
        if (outLen > targetBytes && imageQuality > 25) {
          final factor = targetBytes / outLen;
          final refQuality = (imageQuality * factor).round().clamp(18, 70);
          final refScale = (imageScale * math.sqrt(factor)).clamp(0.2, 0.75);
          try {
            final refinedPath = await PdfManipulator().pdfCompressor(
              params: PDFCompressorParams(
                pdfPath: fileToCompress.path,
                imageQuality: refQuality,
                imageScale: refScale,
                unEmbedFonts: false,
              ),
            );
            if (refinedPath != null) {
              final refFile = File(refinedPath);
              if (await refFile.length() < outLen) {
                outFile = refFile;
              }
            }
          } catch (_) {}
        }
      }
    }

    // 5. Re-apply password protection if originally protected
    if (isProtected && userPassword != null) {
      try {
        final encryptedPath = await PdfManipulator().pdfEncryption(
          params: PDFEncryptionParams(
            pdfPath: outFile.path,
            userPassword: userPassword,
            ownerPassword: userPassword,
            encryptionAES256: true,
          ),
        );
        if (encryptedPath != null) {
          outFile = File(encryptedPath);
        }
      } catch (_) {}
    }

    // 6. Generate final destination file name and path
    final originalName = src.path.split(Platform.pathSeparator).last;
    String outputFileName = _fileNameController.text.trim();
    if (outputFileName.isEmpty) {
      outputFileName = 'Compressed_$originalName';
    } else if (!outputFileName.toLowerCase().endsWith('.pdf')) {
      outputFileName += '.pdf';
    }

    final dir = await getApplicationDocumentsDirectory();
    final uniquePath =
        await FileUtils.getUniqueFilePath(dir.path, outputFileName);
    final savedFile = await outFile.copy(uniquePath);
    final finalFileName = p.basename(uniquePath);
    final finalBytes = await savedFile.length();

    // 7. Get page count for display
    int pageCount = 1;
    try {
      final docBytes = await savedFile.readAsBytes();
      final doc = isProtected && userPassword != null
          ? PdfDocument(inputBytes: docBytes, password: userPassword)
          : PdfDocument(inputBytes: docBytes);
      pageCount = doc.pages.count;
      doc.dispose();
    } catch (_) {}

    // 8. Save to history
    final history = PdfHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: finalFileName,
      path: savedFile.path,
      sizeInBytes: finalBytes,
      createdAt: DateTime.now(),
    );

    if (mounted) {
      context.read<PdfProvider>().addHistory(history);
    }

    return ProcessResult(
      operation: "Compressed",
      filePath: savedFile.path,
      fileName: finalFileName,
      fileSize: finalBytes,
      totalPages: pageCount,
      password: userPassword,
    );
  }

  void _startProcessing() {
    if (_selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a PDF to compress'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_mode == CompressionMode.targetSize) {
      final text = _targetSizeController.text.trim();
      final target = double.tryParse(text);
      if (text.isEmpty || target == null || target <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid target size (greater than 0)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedBytes != null) {
        final targetBytes =
            target * (_targetSizeUnit == 'MB' ? 1024 * 1024 : 1024);
        if (targetBytes >= _selectedBytes!) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Target size ($text $_targetSizeUnit) is greater than or equal to original size (${_formatBytes(_selectedBytes!)}). Please enter a smaller target.',
              ),
              backgroundColor: Colors.orange.shade800,
            ),
          );
          return;
        }
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(
          title: 'Compressing PDF...',
          task: _compressPdfTask,
        ),
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
          'Compress PDF',
          style: TextStyle(
            color: appColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: appColors.text),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── File Selection Card ──
              _buildFileSection(appColors),

              if (_selectedPdf != null) ...[
                const SizedBox(height: 18),

                // ── Option 1: Compression Level Side by Side ──
                _buildSideBySideLevels(appColors),

                // ── OR Divider 1 ──
                _buildOrDivider(appColors),

                // ── Option 2: Percentage Slider ──
                _buildPercentageSection(appColors),

                // ── OR Divider 2 ──
                _buildOrDivider(appColors),

                // ── Option 3: Targeted Size ──
                _buildTargetSizeSection(appColors),

                const SizedBox(height: 18),

                // ── Output File Name ──
                SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _fileNameController,
                    style: TextStyle(color: appColors.text, fontSize: 14),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: appColors.divider ?? Colors.grey.shade200,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: appColors.divider ?? Colors.grey.shade200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Colors.deepOrangeAccent,
                          width: 1.5,
                        ),
                      ),
                      hintText: 'File name (optional)',
                      hintStyle: TextStyle(
                        color: appColors.subtitle?.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.edit_note_rounded,
                        color: appColors.subtitle,
                        size: 22,
                      ),
                      filled: true,
                      fillColor: appColors.surface,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ── Compress Action Button ──
                ElevatedButton.icon(
                  onPressed: _startProcessing,
                  icon: const Icon(Icons.compress_rounded, size: 22),
                  label: const Text(
                    'Compress PDF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrangeAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
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
              color: Colors.deepOrangeAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrangeAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 40,
                  color: Colors.deepOrangeAccent,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Select PDF to Compress',
                style: TextStyle(
                  color: appColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap to browse files',
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

    return Material(
      color: appColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfViewScreen(
                path: _selectedPdf!.path,
                title: fileName,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: appColors.divider ?? Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepOrangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.deepOrangeAccent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                    Row(
                      children: [
                        Text(
                          sizeStr,
                          style: TextStyle(
                            color: appColors.subtitle,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '• Tap to view',
                          style: TextStyle(
                            color: Colors.deepOrangeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _pickPdf,
                child: const Text('Change'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideBySideLevels(AppColors appColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              _mode == CompressionMode.level
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _mode == CompressionMode.level
                  ? Colors.deepOrangeAccent
                  : appColors.subtitle,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Compression Level',
              style: TextStyle(
                color: appColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSideBySideLevelItem(
                appColors: appColors,
                level: CompressionLevel.low,
                title: 'Low',
                subtitle: 'High Quality',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSideBySideLevelItem(
                appColors: appColors,
                level: CompressionLevel.medium,
                title: 'Recommended',
                subtitle: 'Balanced',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSideBySideLevelItem(
                appColors: appColors,
                level: CompressionLevel.high,
                title: 'High',
                subtitle: 'Smallest',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSideBySideLevelItem({
    required AppColors appColors,
    required CompressionLevel level,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _mode == CompressionMode.level && _level == level;

    return GestureDetector(
      onTap: () => setState(() {
        _mode = CompressionMode.level;
        _level = level;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepOrangeAccent.withValues(alpha: 0.1)
              : appColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.deepOrangeAccent
                : (appColors.divider ?? Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Colors.deepOrangeAccent : appColors.subtitle,
              size: 18,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.deepOrangeAccent : appColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: appColors.subtitle,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider(AppColors appColors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: appColors.divider ?? Colors.grey.shade300,
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              'OR',
              style: TextStyle(
                color: appColors.subtitle ?? Colors.grey.shade500,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: appColors.divider ?? Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageSection(AppColors appColors) {
    final isSelected = _mode == CompressionMode.percentage;
    final pctInt = _compressionPercentage.round();
    final estBytes = _selectedBytes != null
        ? (_selectedBytes! * (1.0 - (pctInt / 100.0) * 0.7)).round()
        : null;

    return GestureDetector(
      onTap: () {
        if (_mode != CompressionMode.percentage) {
          setState(() => _mode = CompressionMode.percentage);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: appColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.deepOrangeAccent
                : (appColors.divider ?? Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Colors.deepOrangeAccent
                      : appColors.subtitle,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Percentage Slider',
                  style: TextStyle(
                    color: appColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (estBytes != null) ...[
                  Text(
                    '~${_formatBytes(estBytes)}',
                    style: TextStyle(
                      color: appColors.subtitle,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.deepOrangeAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$pctInt%',
                    style: const TextStyle(
                      color: Colors.deepOrangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.deepOrangeAccent,
                inactiveTrackColor:
                    Colors.deepOrangeAccent.withValues(alpha: 0.2),
                thumbColor: Colors.deepOrangeAccent,
                overlayColor:
                    Colors.deepOrangeAccent.withValues(alpha: 0.2),
                trackHeight: 5,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: _compressionPercentage,
                min: 10,
                max: 90,
                divisions: 16,
                label: '$pctInt%',
                onChanged: (val) {
                  setState(() {
                    _mode = CompressionMode.percentage;
                    _compressionPercentage = val;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSizeSection(AppColors appColors) {
    final isSelected = _mode == CompressionMode.targetSize;

    return GestureDetector(
      onTap: () {
        if (_mode != CompressionMode.targetSize) {
          setState(() => _mode = CompressionMode.targetSize);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: appColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.deepOrangeAccent
                : (appColors.divider ?? Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? Colors.deepOrangeAccent
                  : appColors.subtitle,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Target Size',
              style: TextStyle(
                color: appColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _targetSizeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    color: appColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  onTap: () {
                    if (_mode != CompressionMode.targetSize) {
                      setState(() => _mode = CompressionMode.targetSize);
                    }
                  },
                  onChanged: (_) {
                    if (_mode != CompressionMode.targetSize) {
                      setState(() => _mode = CompressionMode.targetSize);
                    } else {
                      setState(() {});
                    }
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    hintText: 'Enter size',
                    hintStyle: TextStyle(
                      color: appColors.subtitle?.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: appColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: appColors.divider ?? Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: appColors.divider ?? Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.deepOrangeAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: appColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: appColors.divider ?? Colors.grey.shade300,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _targetSizeUnit,
                  dropdownColor: appColors.surface,
                  style: TextStyle(
                    color: appColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'KB', child: Text('KB')),
                    DropdownMenuItem(value: 'MB', child: Text('MB')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _mode = CompressionMode.targetSize;
                        _targetSizeUnit = val;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
