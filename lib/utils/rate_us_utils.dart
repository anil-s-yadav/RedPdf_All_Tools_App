import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

class RateUsUtils {
  static const String _successCountKey = 'success_count_rate_us';

  static Future<void> showRateUsDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Increment success count
    int count = (prefs.getInt(_successCountKey) ?? 0) + 1;
    await prefs.setInt(_successCountKey, count);

    // Ask for native review every 3 successful operations
    if (count % 3 == 0) {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        inAppReview.requestReview();
      }
    }
  }

  static Future<void> openStoreListing() async {
    final InAppReview inAppReview = InAppReview.instance;
    await inAppReview.openStoreListing(appStoreId: 'com.legendarysoftware.redpdf_imagetopdf');
  }
}
