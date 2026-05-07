import 'package:flutter/material.dart';
import 'package:redpdf_tools/theme/app_theme.dart';
import 'package:redpdf_tools/screens/success_screen.dart';

class ProcessResult {
  final String operation;
  final String filePath;
  final String fileName;
  final int fileSize;
  final int totalPages;

  ProcessResult({
    required this.operation,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.totalPages,
  });
}

class ProcessingScreen extends StatefulWidget {
  final Future<ProcessResult> Function() task;
  final String title;

  const ProcessingScreen({
    super.key,
    required this.task,
    this.title = "Processing...",
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    // Use Future.delayed to ensure the frame is rendered before starting heavy work
    Future.delayed(const Duration(milliseconds: 300), () {
      _startTask();
    });
  }

  Future<void> _startTask() async {
    try {
      final result = await widget.task();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            operation: result.operation,
            filePath: result.filePath,
            fileName: result.fileName,
            fileSize: result.fileSize,
            totalPages: result.totalPages,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Go back to settings screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).appColors;
    return Scaffold(
      backgroundColor: appColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: appColors.primary!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: appColors.primary,
                  strokeWidth: 4,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.title,
              style: TextStyle(
                color: appColors.text,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please wait while we process your document.\nThis might take a few moments.',
              textAlign: TextAlign.center,
              style: TextStyle(color: appColors.subtitle, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
