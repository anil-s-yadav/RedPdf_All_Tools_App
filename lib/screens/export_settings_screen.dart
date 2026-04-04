import 'dart:io';
import 'package:flutter/material.dart';
import 'package:redpdf_tools/theme/app_theme.dart';
import 'success_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:redpdf_tools/providers/pdf_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:math' as math;
import 'package:redpdf_tools/providers/settings_provider.dart';
import 'package:redpdf_tools/models/pdf_history.dart';
import '../utils/file_utils.dart';
import 'package:path/path.dart' as p;

class ExportSettingsScreen extends StatefulWidget {
  final List<File> images;

  const ExportSettingsScreen({super.key, required this.images});

  @override
  State<ExportSettingsScreen> createState() => _ExportSettingsScreenState();
}

class _ExportSettingsScreenState extends State<ExportSettingsScreen> {
  final TextEditingController _fileNameController = TextEditingController(
    text: 'Project_Final_Draft',
  );
  final TextEditingController _userPasswordController = TextEditingController();
  final TextEditingController _ownerPasswordController =
      TextEditingController();

  bool _isHighCompression = false;
  bool _securityEnabled = false;
  bool _allowPrinting = true;
  bool _allowCopying = true;
  bool _isGenerating = false;

  Future<Uint8List> _processImage(File file) async {
    if (_isHighCompression) {
      final compressed = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: 50, // High compression
      );
      return compressed ?? await file.readAsBytes();
    }
    return await file.readAsBytes();
  }

  PdfPageFormat _getPageFormat(SettingsProvider settings) {
    PdfPageFormat format;
    switch (settings.defaultPageSize) {
      case PdfPageSize.a4:
        format = PdfPageFormat.a4;
        break;
      case PdfPageSize.letter:
        format = PdfPageFormat.letter;
        break;
      case PdfPageSize.a3:
        format = PdfPageFormat.a3;
        break;
      case PdfPageSize.legal:
        format = PdfPageFormat.legal;
        break;
    }

    if (settings.defaultOrientation == PdfPageOrientation.landscape) {
      return format.landscape;
    }
    return format;
  }

  Future<void> _generateAndSavePdf() async {
    setState(() => _isGenerating = true);

    try {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final pdf = pw.Document();
      final pageFormat = _getPageFormat(settings);

      for (var imageFile in widget.images) {
        final imageBytes = await _processImage(imageFile);
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
            },
          ),
        );
      }

      final bytes = await pdf.save();

      final dir = await getApplicationDocumentsDirectory();
      final name = _fileNameController.text.trim().isEmpty
          ? 'Untitled_Document'
          : _fileNameController.text;

      final uniquePath = await FileUtils.getUniqueFilePath(
        dir.path,
        '$name.pdf',
      );
      final file = File(uniquePath);
      final finalFileName = p.basename(uniquePath);

      await file.writeAsBytes(bytes);

      // Save to history
      final history = PdfHistory(
        id: Uuid().v4(),
        title: finalFileName,
        path: file.path,
        sizeInBytes: bytes.length,
        createdAt: DateTime.now(),
      );

      if (!mounted) return;
      context.read<PdfProvider>().addHistory(history);

      setState(() => _isGenerating = false);

      // Go to Success Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            operation: "Created",
            filePath: file.path,
            fileName: finalFileName,
            fileSize: bytes.length,
            totalPages: widget.images.length,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }

  double _getTotalOriginalSize() {
    double total = 0;
    for (var image in widget.images) {
      if (image.existsSync()) {
        total += image.lengthSync();
      }
    }
    return total;
  }

  String _getFormattedSize(double bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return "${(bytes / math.pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}";
  }

  String _getEstimatedSize() {
    double originalSize = _getTotalOriginalSize();
    double estimated = _isHighCompression
        ? originalSize * 0.3
        : originalSize * 0.8;
    return _getFormattedSize(estimated);
  }

  void _showOwnerPasswordInfo(BuildContext context) {
    final appColors = Theme.of(context).appColors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.security, color: appColors.primary),
            const SizedBox(width: 10),
            Text('Password Types', style: TextStyle(color: appColors.text)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Password:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: appColors.text,
              ),
            ),
            Text(
              'Required to open and view the PDF document.',
              style: TextStyle(color: appColors.subtitle),
            ),
            const SizedBox(height: 12),
            Text(
              'Owner Password:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: appColors.text,
              ),
            ),
            Text(
              'Required to change permissions (like printing or copying) and other administrative settings.',
              style: TextStyle(color: appColors.subtitle),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'GOT IT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).appColors;
    final settings = Provider.of<SettingsProvider>(context);
    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        backgroundColor: appColors.background,
        elevation: 0,
        title: Text(
          'Export Settings',
          style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: appColors.text),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('FILE DETAILS', appColors),
              Text(
                'File Name',
                style: TextStyle(color: appColors.subtitle, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: appColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: appColors.divider ?? Colors.grey.shade200,
                  ),
                ),
                child: TextField(
                  controller: _fileNameController,
                  style: TextStyle(color: appColors.text),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    border: InputBorder.none,
                    suffixIcon: Container(
                      decoration: BoxDecoration(
                        color: appColors.primary!.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Icon(
                        Icons.picture_as_pdf,
                        color: appColors.primary,
                      ),
                    ),
                  ),
                ),
              ),

              _buildSectionTitle('COMPRESSION', appColors),
              Row(
                children: [
                  _buildCompressionCard(
                    'Normal',
                    'Best quality',
                    Icons.high_quality,
                    !_isHighCompression,
                    appColors,
                    () {
                      setState(() => _isHighCompression = false);
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildCompressionCard(
                    'Small File',
                    'Lower quality',
                    Icons.compress,
                    _isHighCompression,
                    appColors,
                    () {
                      setState(() => _isHighCompression = true);
                    },
                  ),
                ],
              ),

              // const SizedBox(height: 24),
              _buildSectionTitle('Page Settings', appColors),
              // _buildListTile(
              //   context,
              //   Icons.insert_drive_file_outlined,
              //   'Page Size',
              //   trailing: Text(
              //     settings.pageSizeString,
              //     style: const TextStyle(
              //       color: Color(0xFF64748B),
              //       fontWeight: FontWeight.w500,
              //     ),
              //   ),
              //   onTap: () => _showPageSizeDialog(context, settings),
              // ),
              ListTile(
                title: Text(
                  'Page Size',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: appColors.text,
                  ),
                ),
                trailing: Text(
                  settings.pageSizeString,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                onTap: () => _showPageSizeDialog(context, settings),
              ),
              ListTile(
                // contentPadding: EdgeInsets.symmetric(vertical: 0),
                title: Text(
                  'Page Orientation',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: appColors.text,
                  ),
                ),
                trailing: Text(
                  settings.orientationString,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                onTap: () => _showOrientationDialog(context, settings),
              ),
              // const SizedBox(height: 24),
              // _buildListTile(context, Icons.insert_drive_file_outlined),
              // const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('SECURITY', appColors),
                  Switch(
                    value: _securityEnabled,
                    onChanged: (val) => setState(() => _securityEnabled = val),
                    activeThumbColor: Colors.white,
                    activeTrackColor: appColors.primary,
                  ),
                ],
              ),
              if (_securityEnabled) ...[
                Text(
                  'User Password',
                  style: TextStyle(color: appColors.subtitle, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: appColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: appColors.divider ?? Colors.grey.shade200,
                    ),
                  ),
                  child: TextField(
                    controller: _userPasswordController,
                    obscureText: true,
                    style: TextStyle(color: appColors.text),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      border: InputBorder.none,
                      hintText: 'Set opening password',
                      hintStyle: TextStyle(
                        color: appColors.subtitle?.withOpacity(0.5),
                      ),
                      suffixIcon: const Icon(
                        Icons.visibility_off,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Owner Password',
                      style: TextStyle(color: appColors.subtitle, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _showOwnerPasswordInfo(context),
                      child: Icon(
                        Icons.help_outline,
                        size: 16,
                        color: appColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: appColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: appColors.divider ?? Colors.grey.shade200,
                    ),
                  ),
                  child: TextField(
                    controller: _ownerPasswordController,
                    obscureText: true,
                    style: TextStyle(color: appColors.text),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      border: InputBorder.none,
                      hintText: 'Set administrative password',
                      hintStyle: TextStyle(
                        color: appColors.subtitle?.withOpacity(0.5),
                      ),
                      suffixIcon: const Icon(
                        Icons.visibility_off,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],

              _buildSectionTitle('PERMISSIONS', appColors),
              _buildPermissionCard(
                'Allow Printing',
                _allowPrinting,
                appColors,
                (val) => setState(() => _allowPrinting = val ?? false),
              ),
              _buildPermissionCard(
                'Allow Copying',
                _allowCopying,
                appColors,
                (val) => setState(() => _allowCopying = val ?? false),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: appColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
          border: Border(
            top: BorderSide(color: appColors.divider ?? Colors.transparent),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 14, color: appColors.subtitle),
                  const SizedBox(width: 6),
                  Text(
                    'Estimated File Size: ',
                    style: TextStyle(color: appColors.subtitle, fontSize: 13),
                  ),
                  Text(
                    _getEstimatedSize(),
                    style: TextStyle(
                      color: appColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateAndSavePdf,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download, color: Colors.white),
                label: Text(
                  _isGenerating ? 'GENERATING...' : 'Save & Export PDF',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppColors appColors) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.2,
          color: appColors.subtitle,
        ),
      ),
    );
  }

  Widget _buildCompressionCard(
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    AppColors appColors,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? appColors.primary!.withOpacity(0.1)
                : appColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? appColors.primary!
                  : (appColors.divider ?? Colors.grey.shade300),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? appColors.primary : appColors.subtitle,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isSelected ? appColors.primary : appColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? appColors.primary!.withOpacity(0.7)
                      : appColors.subtitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard(
    String title,
    bool isSelected,
    AppColors appColors,
    ValueChanged<bool?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? appColors.primary!.withOpacity(0.05)
            : appColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected
              ? appColors.primary!.withOpacity(0.2)
              : (appColors.divider ?? Colors.transparent),
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: appColors.text,
          ),
        ),
        value: isSelected,
        onChanged: onChanged,
        activeColor: appColors.primary,
        checkColor: Colors.white,
        side: BorderSide(
          color: appColors.subtitle?.withOpacity(0.3) ?? Colors.grey.shade300,
          width: 2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  void _showPageSizeDialog(BuildContext context, SettingsProvider settings) {
    final appColors = Theme.of(context).appColors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Page Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PdfPageSize.values.map((size) {
            return ListTile(
              title: Text(size.toString().split('.').last.toUpperCase()),
              trailing: settings.defaultPageSize == size
                  ? Icon(Icons.check, color: appColors.primary)
                  : null,
              onTap: () {
                settings.setDefaultPageSize(size);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showOrientationDialog(BuildContext context, SettingsProvider settings) {
    final appColors = Theme.of(context).appColors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Orientation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PdfPageOrientation.values.map((orientation) {
            return ListTile(
              title: Text(
                orientation.toString().split('.').last[0].toUpperCase() +
                    orientation.toString().split('.').last.substring(1),
              ),
              trailing: settings.defaultOrientation == orientation
                  ? Icon(Icons.check, color: appColors.primary)
                  : null,
              onTap: () {
                settings.setDefaultOrientation(orientation);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
