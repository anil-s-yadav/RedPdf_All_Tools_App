import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:redpdf_tools/theme/app_theme.dart';

class PdfViewScreen extends StatefulWidget {
  final String path;
  final String title;

  const PdfViewScreen({super.key, required this.path, required this.title});

  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();

  Future<String?> _askPassword(BuildContext context) async {
    final appColors = Theme.of(context).appColors;
    String? password;
    final textController = TextEditingController();

    // Avoid re-prompting while already prompting if pdfrx calls it repeatedly but wait,
    // pdfrx awaits the future.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appColors.surface,
          title: Text(
            'Password Required',
            style: TextStyle(
              color: appColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: textController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter PDF password',
              hintStyle: TextStyle(color: appColors.subtitle),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: appColors.divider ?? Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: appColors.primary ?? Colors.blue),
              ),
            ),
            style: TextStyle(color: appColors.text),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                password = null;
                Navigator.of(context).pop();
                Navigator.of(
                  context,
                ).pop(); // Close the viewer screen since it was cancelled
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: appColors.subtitle),
              ),
            ),
            TextButton(
              onPressed: () {
                password = textController.text;
                Navigator.of(context).pop();
              },
              child: Text('Open', style: TextStyle(color: appColors.primary)),
            ),
          ],
        );
      },
    );
    return password;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).appColors;
    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            color: appColors.text,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: appColors.background,
        iconTheme: IconThemeData(color: appColors.text),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: appColors.primary),
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  files: [XFile(widget.path)],
                  text: 'Check out this PDF!',
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PdfViewer.file(
            widget.path,
            controller: _pdfViewerController,
            passwordProvider: () => _askPassword(context),
            params: const PdfViewerParams(
              maxScale: 8.0,
              backgroundColor: Colors.transparent,
              textSelectionParams: PdfTextSelectionParams(enabled: false),
              verticalCacheExtent: 5.0,
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: PdfPageIndicator(controller: _pdfViewerController),
          ),
        ],
      ),
    );
  }
}

class PdfPageIndicator extends StatefulWidget {
  final PdfViewerController controller;
  const PdfPageIndicator({super.key, required this.controller});

  @override
  State<PdfPageIndicator> createState() => _PdfPageIndicatorState();
}

class _PdfPageIndicatorState extends State<PdfPageIndicator> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.isReady || widget.controller.pageNumber == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${widget.controller.pageNumber} / ${widget.controller.pages.length}',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
