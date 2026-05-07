import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:redpdf_tools/theme/app_theme.dart';

class RateUsUtils {
  static const String _neverShowKey = 'never_show_rate_us';

  static Future<void> showRateUsDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final neverShow = prefs.getBool(_neverShowKey) ?? false;

    if (neverShow) return;

    if (!context.mounted) return;

    final appColors = Theme.of(context).appColors;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: appColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 30),
              const SizedBox(width: 10),
              Text(
                'Enjoying RedPdf?',
                style: TextStyle(
                  color: appColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'If you find this tool useful, please take a moment to rate us! It helps us improve.',
                style: TextStyle(color: appColors.subtitle, fontSize: 16),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          actions: [
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: appColors.primary!),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: appColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await prefs.setBool(_neverShowKey, true);
                          Navigator.pop(context);
                          _launchStore();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: appColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Rate Us',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await prefs.setBool(_neverShowKey, true);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Ignore Permanently',
                      style: TextStyle(
                        color: appColors.subtitle!.withOpacity(0.7),
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static void _launchStore() async {
    // Replace with your actual package name or store URL
    const url =
        'https://play.google.com/store/apps/details?id=com.legendarysoftware.imagetopdf';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
