import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Policy")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text('''
Privacy Policy

Last Updated: March 2026

Thank you for using Image to PDF Converter.

1. Information We Collect
This app does NOT collect, store, or share any personal information.

2. Storage Permission
The app requests storage permission only to:
- Access images selected by the user
- Save generated PDF files to the device

We do NOT upload files to any server.
All processing happens locally on your device.

3. Internet Usage
This app works completely offline.
It does not require an internet connection.

4. Data Sharing
We do not sell, trade, or share any user data with third parties.

5. Children’s Privacy
This app does not knowingly collect data from children.

6. Changes to This Policy
If we update our privacy policy, changes will be reflected on this page.

7. Contact Us
For any questions, contact:
your@email.com

By using this app, you agree to this privacy policy.
            ''', style: TextStyle(fontSize: 15, height: 1.6)),
        ),
      ),
    );
  }
}
