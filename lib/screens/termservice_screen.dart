import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Terms of Service")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text('''
Terms of Service

Last Updated: March 2026

Welcome to Image to PDF Converter.

By using this application, you agree to the following terms:

1. Use of the App
This app is provided for personal and lawful use only.
You agree not to misuse the app or attempt to reverse engineer, modify, or redistribute it.

2. No Warranty
This app is provided "as is" without any warranties.
We do not guarantee that the app will be error-free or uninterrupted.

3. Limitation of Liability
The developer is not responsible for:
- Loss of files
- Data corruption
- Device damage
- Any indirect or consequential damages

Users are responsible for backing up their important files.

4. Intellectual Property
All app content, design, and branding are owned by the developer.
You may not copy or distribute any part of the app without permission.

5. Modifications
We may update or modify the app and these terms at any time.

6. Termination
We reserve the right to stop providing the app at any time without notice.

7. Contact
For questions, contact:
your@email.com

By using this app, you agree to these Terms of Service.
            ''', style: TextStyle(fontSize: 15, height: 1.6)),
        ),
      ),
    );
  }
}
