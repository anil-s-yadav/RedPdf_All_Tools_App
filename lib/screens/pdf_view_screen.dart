import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:redpdf_tools/theme/app_theme.dart';

class PdfViewScreen extends StatelessWidget {
  final String path;
  final String title;

  const PdfViewScreen({super.key, required this.path, required this.title});

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
            style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold),
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
                Navigator.of(context).pop(); // Close the viewer screen since it was cancelled
              },
              child: Text('Cancel', style: TextStyle(color: appColors.subtitle)),
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
          title,
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
              Share.shareXFiles([XFile(path)], text: 'Check out this PDF!');
            },
          ),
        ],
      ),
      body: PdfViewer.file(
        path,
        passwordProvider: () => _askPassword(context),
      ),
    );
  }
}
