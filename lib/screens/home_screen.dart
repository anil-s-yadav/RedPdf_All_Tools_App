import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:redpdf_tools/screens/pdf_view_screen.dart';
import '../providers/pdf_provider.dart';
import 'package:redpdf_tools/theme/app_theme.dart';
import '../utils/file_utils.dart';
import 'package:path/path.dart' as p;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    return Scaffold(
      backgroundColor: appColors.background,
      appBar: AppBar(
        backgroundColor: appColors.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Convert PDF - all tools',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: appColors.text,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select any document or image to get started',
              style: TextStyle(fontSize: 14, color: appColors.subtitle),
            ),
          ],
        ),
        toolbarHeight: 150,
        elevation: 0,
        // Go to Buy Premium page
        // actions: [
        //   GestureDetector(
        //     onTap: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(builder: (_) => const PackagesScreen()),
        //       );
        //     },
        //     child: Container(
        //       margin: const EdgeInsets.only(right: 25),
        //       child: CircleAvatar(
        //         backgroundColor: appColors.divider,
        //         radius: 30,
        //         child: const Icon(
        //           Icons.workspace_premium,
        //           color: Colors.amber,
        //           size: 35,
        //         ),
        //       ),
        //     ),
        //   ),
        // ],
      ),
      body: DefaultTabController(
        length: 2,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 50),
                  decoration: BoxDecoration(
                    color: appColors.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: appColors.divider ?? Colors.grey.shade200,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  child: TextField(
                    onChanged: (value) {
                      context.read<PdfProvider>().setSearchQuery(value);
                    },
                    style: TextStyle(color: appColors.text),
                    decoration: InputDecoration(
                      icon: Icon(Icons.search, color: appColors.subtitle),
                      hintText: 'Search files...',
                      hintStyle: TextStyle(
                        color: appColors.subtitle?.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: TabBar(
                        labelStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: appColors.text,
                        ),
                        unselectedLabelColor: appColors.subtitle,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerColor: appColors.divider,
                        indicatorColor: appColors.primary,
                        tabs: const [
                          Tab(text: 'History'),
                          Tab(text: 'All files'),
                        ],
                      ),
                    ),

                    GestureDetector(
                      onTap: () => _showClearHistoryDialog(context),
                      child: Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: appColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      const _PdfList(isHistory: true),
                      const _PdfList(isHistory: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PdfProvider>().clearAllHistory();
            },
            child: const Text(
              'Clear history',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfList extends StatelessWidget {
  final bool isHistory;
  const _PdfList({required this.isHistory});

  IconData _getIconForTitle(String title) {
    if (title.toLowerCase().contains('report')) return Icons.analytics;
    if (title.toLowerCase().contains('invoice')) return Icons.receipt;
    return Icons.insert_drive_file;
  }

  static const List<Color> _randomColors = [
    Colors.blue,
    Colors.teal,
    Colors.orange,
    Colors.purple,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
    Colors.amber,
  ];

  Color _getIconColor(String title) {
    final int index = title.hashCode % _randomColors.length;
    return _randomColors[index.abs()];
  }

  Color _getBgColor(String title, Color? baseColor) {
    final int index = title.hashCode % _randomColors.length;
    return _randomColors[index.abs()].withOpacity(0.2);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    return RefreshIndicator(
      onRefresh: () => context.read<PdfProvider>().scanAllPdfs(),
      child: Consumer<PdfProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading || (provider.isScanning && !isHistory)) {
            return Center(
              child: CircularProgressIndicator(color: appColors.primary),
            );
          }

          final list = isHistory ? provider.history : provider.allFiles;

          if (list.isEmpty) {
            return Center(
              child: Text(
                isHistory ? 'No history found.' : 'No PDF files found.',
                style: TextStyle(color: appColors.subtitle),
              ),
            );
          }

          return ListView.builder(
            itemCount: list.length,
            padding: const EdgeInsets.only(top: 16, bottom: 80),
            itemBuilder: (context, index) {
              final item = list[index];
              final title = item.title;
              final dateStr = DateFormat('MMM d, yyyy').format(item.createdAt);
              final sizeStr = _formatSize(item.sizeInBytes);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: appColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: appColors.divider ?? Colors.transparent,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: _getBgColor(title, appColors.lightPrimary),
                    child: Icon(
                      _getIconForTitle(title),
                      color: _getIconColor(title),
                    ),
                  ),
                  title: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: appColors.text,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '$dateStr • $sizeStr',
                      style: TextStyle(color: appColors.subtitle, fontSize: 13),
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: appColors.subtitle),
                    onSelected: (value) async {
                      if (value == 'open') {
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfViewScreen(
                              path: item.path,
                              title: item.title,
                            ),
                          ),
                        );
                      } else if (value == 'share') {
                        await Share.shareXFiles([
                          XFile(item.path),
                        ], text: 'Check out my PDF!');
                      } else if (value == 'save') {
                        try {
                          final savedPath = await FileUtils.saveToDevice(
                            sourcePath: item.path,
                            fileName: item.title,
                          );
                          if (savedPath != null) {
                            final finalFileName = p.basename(savedPath);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Saved to Download/RedPdf/$finalFileName',
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                showCloseIcon: true,
                              ),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving file: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else if (value == 'delete') {
                        final file = File(item.path);
                        if (await file.exists()) {
                          await file.delete();
                        }
                        if (isHistory) {
                          provider.removeHistory(item.id);
                        } else {
                          provider.scanAllPdfs();
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Text('Open PDF'),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Text('Share PDF'),
                      ),
                      const PopupMenuItem(
                        value: 'save',
                        child: Text('Save to device'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PdfViewScreen(path: item.path, title: item.title),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
