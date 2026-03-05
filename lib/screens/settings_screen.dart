import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:redpdf_tools/screens/privicypolicy_screen.dart';
import 'package:redpdf_tools/screens/termservice_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import 'package:redpdf_tools/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _cacheSize = '0 B';

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = await _getDirSize(tempDir);

      if (mounted) {
        setState(() {
          _cacheSize = _formatSize(totalSize);
        });
      }
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
    }
  }

  Future<int> _getDirSize(Directory dir) async {
    int totalSize = 0;
    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting dir size: $e');
    }
    return totalSize;
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _clearCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final entities = tempDir.listSync();
        for (final entity in entities) {
          if (entity is File) {
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        }
      }

      await _calculateCacheSize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 24),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildCardContainer({
    required List<Widget> children,
    required BuildContext context,
  }) {
    final appColors = Theme.of(context).appColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: appColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColors.divider ?? Colors.grey.shade100),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    IconData icon,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
    bool showDivider = true,
    Color? iconColor,
    Color? textColor,
  }) {
    final appColors = Theme.of(context).appColors;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          leading: Icon(icon, color: iconColor ?? appColors.primary, size: 24),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: textColor ?? appColors.text,
            ),
          ),
          trailing:
              trailing ??
              Icon(
                Icons.chevron_right,
                color: appColors.subtitle?.withOpacity(0.3),
                size: 20,
              ),
          onTap: onTap,
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Divider(
              height: 1,
              thickness: 1,
              color: appColors.divider?.withOpacity(0.5),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    // final authProvider = Provider.of<AuthProvider>(context);
    final appColors = Theme.of(context).appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // final user = authProvider.userModel;
    // final isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      backgroundColor: appColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              // Container(
              //   width: double.infinity,
              //   margin: const EdgeInsets.all(16),
              //   padding: const EdgeInsets.symmetric(
              //     vertical: 32,
              //     horizontal: 16,
              //   ),
              //   decoration: BoxDecoration(
              //     color: isDark ? appColors.surface : const Color(0xFFFFF8F8),
              //     borderRadius: BorderRadius.circular(32),
              //     border: Border.all(
              //       color: appColors.primary!.withOpacity(0.05),
              //     ),
              //   ),
              //   child: Column(
              //     children: [
              //       Stack(
              //         alignment: Alignment.bottomRight,
              //         children: [
              //           Container(
              //             padding: const EdgeInsets.all(4),
              //             decoration: BoxDecoration(
              //               shape: BoxShape.circle,
              //               border: Border.all(
              //                 color: Colors.grey.shade200,
              //                 width: 2,
              //               ),
              //             ),
              //             child: CircleAvatar(
              //               radius: 50,
              //               backgroundImage: user?.photoUrl != null
              //                   ? NetworkImage(user!.photoUrl!) as ImageProvider
              //                   : null,
              //               child: user?.photoUrl == null
              //                   ? Icon(
              //                       Icons.person,
              //                       size: 50,
              //                       color: appColors.subtitle,
              //                     )
              //                   : null,
              //             ),
              //           ),
              //           if (user?.hasPremiumAccess ?? false)
              //             Container(
              //               padding: const EdgeInsets.all(4),
              //               decoration: const BoxDecoration(
              //                 color: Colors.white,
              //                 shape: BoxShape.circle,
              //               ),
              //               child: Icon(
              //                 Icons.verified,
              //                 color: appColors.primary,
              //                 size: 24,
              //               ),
              //             ),
              //         ],
              //       ),
              //       const SizedBox(height: 16),
              //       Text(
              //         isAuthenticated
              //             ? (user?.displayName ?? 'User')
              //             : 'Guest User',
              //         style: TextStyle(
              //           fontSize: 24,
              //           fontWeight: FontWeight.bold,
              //           color: appColors.text,
              //         ),
              //       ),
              //       const SizedBox(height: 4),
              //       Text(
              //         isAuthenticated
              //             ? (user?.email ?? '')
              //             : 'Log in to unlock 100-day free trial',
              //         style: TextStyle(color: appColors.subtitle, fontSize: 14),
              //       ),
              //       const SizedBox(height: 20),
              //       if (isAuthenticated)
              //         Row(
              //           mainAxisAlignment: MainAxisAlignment.center,
              //           children: [
              //             if (user?.hasPremiumAccess ?? false)
              //               Container(
              //                 padding: const EdgeInsets.symmetric(
              //                   horizontal: 16,
              //                   vertical: 8,
              //                 ),
              //                 decoration: BoxDecoration(
              //                   color: const Color(0xFFFFEAEA),
              //                   borderRadius: BorderRadius.circular(12),
              //                 ),
              //                 child: Text(
              //                   user?.isPremium ?? false
              //                       ? 'PRO MEMBER'
              //                       : 'FREE TRIAL',
              //                   style: const TextStyle(
              //                     color: Color(0xFFFF4E50),
              //                     fontWeight: FontWeight.bold,
              //                     fontSize: 12,
              //                   ),
              //                 ),
              //               ),
              //             const SizedBox(width: 8),
              //             GestureDetector(
              //               onTap: () {
              //                 Navigator.push(
              //                   context,
              //                   MaterialPageRoute(
              //                     builder: (_) => const PackagesScreen(),
              //                   ),
              //                 );
              //               },
              //               child: Container(
              //                 padding: const EdgeInsets.symmetric(
              //                   horizontal: 16,
              //                   vertical: 8,
              //                 ),
              //                 decoration: BoxDecoration(
              //                   color: const Color(0xFFFF4E50),
              //                   borderRadius: BorderRadius.circular(12),
              //                 ),
              //                 child: const Text(
              //                   'Manage Plan',
              //                   style: TextStyle(
              //                     color: Colors.white,
              //                     fontWeight: FontWeight.bold,
              //                     fontSize: 12,
              //                   ),
              //                 ),
              //               ),
              //             ),
              //           ],
              //         )
              //       else
              //         SizedBox(
              //           width: 140,
              //           height: 48,
              //           child: ElevatedButton(
              //             onPressed: () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(
              //                   builder: (_) => const LoginScreen(),
              //                 ),
              //               );
              //             },
              //             style: ElevatedButton.styleFrom(
              //               backgroundColor: appColors.primary,
              //               shape: RoundedRectangleBorder(
              //                 borderRadius: BorderRadius.circular(24),
              //               ),
              //               elevation: 0,
              //             ),
              //             child: const Text(
              //               'Sign In',
              //               style: TextStyle(
              //                 color: Colors.white,
              //                 fontWeight: FontWeight.bold,
              //               ),
              //             ),
              //           ),
              //         ),
              //     ],
              //   ),
              // ),
              _buildSectionHeader(context, 'General'),
              _buildCardContainer(
                context: context,
                children: [
                  _buildListTile(
                    context,
                    Icons.dark_mode_outlined,
                    'Dark Mode',
                    trailing: Switch(
                      value: isDark,
                      onChanged: (val) => themeProvider.toggleDarkMode(val),
                      activeThumbColor: appColors.primary,
                    ),
                  ),
                  _buildListTile(
                    context,
                    Icons.insert_drive_file_outlined,
                    'Default Page Size',
                    trailing: Text(
                      settings.pageSizeString,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => _showPageSizeDialog(context, settings),
                  ),
                  _buildListTile(
                    context,
                    Icons.screen_rotation_outlined,
                    'Default Orientation',
                    trailing: Text(
                      settings.orientationString,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => _showOrientationDialog(context, settings),
                    showDivider: false,
                  ),
                ],
              ),

              // _buildSectionHeader(context, 'Security'),
              // _buildCardContainer(
              //   context: context,
              //   children: [
              //     _buildListTile(
              //       context,
              //       Icons.lock_outline,
              //       'App Lock',
              //       trailing: Switch(
              //         value: true,
              //         onChanged: (val) {},
              //         activeThumbColor: appColors.primary,
              //       ),
              //     ),
              //     _buildListTile(
              //       context,
              //       Icons.password_outlined,
              //       'Manage Passwords',
              //       showDivider: false,
              //     ),
              //   ],
              // ),
              _buildSectionHeader(context, 'Storage & Backup'),
              _buildCardContainer(
                context: context,
                children: [
                  // _buildListTile(
                  //   context,
                  //   Icons.cloud_upload_outlined,
                  //   'Auto-save to cloud',
                  //   trailing: Switch(
                  //     value: false,
                  //     onChanged: (val) {},
                  //     activeThumbColor: Colors.blue.shade100,
                  //     activeTrackColor: Colors.blue.shade50,
                  //   ),
                  // ),
                  _buildListTile(
                    context,
                    Icons.delete_outline,
                    'Clear Cache',
                    trailing: Text(
                      _cacheSize,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                      ),
                    ),
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Wants to clear caches!"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              _clearCache();
                              Navigator.pop(context);
                            },
                            child: Text("Clear Now"),
                          ),
                        ],
                      ),
                    ),
                    textColor: Colors.redAccent,
                    iconColor: Colors.redAccent,
                    showDivider: false,
                  ),
                ],
              ),

              _buildSectionHeader(context, 'Support & Info'),
              _buildCardContainer(
                context: context,
                children: [
                  //  _buildListTile(context, Icons.star_border, 'Rate App'),
                  _buildListTile(
                    context,
                    Icons.help_outline,
                    'Try Our Other Tools',
                    trailing: const Icon(
                      Icons.open_in_new,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    ),
                    onTap: () => _launchUrl(
                      "https://play.google.com/store/apps/dev?id=8832237281097064209",
                    ),
                  ),
                  _buildListTile(
                    context,
                    Icons.description_outlined,
                    'Terms of Service',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsOfServiceScreen(),
                      ),
                    ),
                  ),
                  _buildListTile(
                    context,
                    Icons.privacy_tip_outlined,
                    'Privacy Policy',
                    showDivider: false,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              // if (isAuthenticated)
              //   Padding(
              //     padding: const EdgeInsets.symmetric(horizontal: 24),
              //     child: SizedBox(
              //       width: double.infinity,
              //       height: 56,
              //       child: OutlinedButton.icon(
              //         onPressed: () => authProvider.signOut(),
              //         icon: const Icon(Icons.logout, color: Colors.redAccent),
              //         label: const Text(
              //           'Log Out',
              //           style: TextStyle(
              //             fontSize: 16,
              //             fontWeight: FontWeight.bold,
              //             color: Colors.redAccent,
              //           ),
              //         ),
              //         style: OutlinedButton.styleFrom(
              //           side: const BorderSide(color: Color(0xFFFEE2E2)),
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(28),
              //           ),
              //           backgroundColor: const Color(0xFFF8FAFC),
              //         ),
              //       ),
              //     ),
              //   ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Version 1.0.0 (Build 1)',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
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

  Future<void> _launchUrl(String uri) async {
    if (!await launchUrl(Uri.parse(uri))) {
      throw Exception('Could not launch $uri');
    }
  }
}
