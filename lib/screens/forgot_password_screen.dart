// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../theme/app_theme.dart';

// class ForgotPasswordScreen extends StatefulWidget {
//   const ForgotPasswordScreen({super.key});

//   @override
//   State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
// }

// class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
//   final _emailController = TextEditingController();

//   @override
//   void dispose() {
//     _emailController.dispose();
//     super.dispose();
//   }

//   Future<void> _resetPassword() async {
//     final auth = context.read<AuthProvider>();
//     try {
//       await auth.sendPasswordResetEmail(_emailController.text.trim());
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Password reset link sent to your email.'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final appColors = Theme.of(context).appColors;
//     final auth = context.watch<AuthProvider>();

//     return Scaffold(
//       backgroundColor: appColors.background,
//       appBar: AppBar(
//         backgroundColor: appColors.background,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: appColors.text),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Reset Password',
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: appColors.text,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Enter your email and we will send you a link to reset your password.',
//                 style: TextStyle(fontSize: 16, color: appColors.subtitle),
//               ),
//               const SizedBox(height: 40),
//               TextField(
//                 controller: _emailController,
//                 style: TextStyle(color: appColors.text),
//                 decoration: InputDecoration(
//                   labelText: 'Email Address',
//                   labelStyle: TextStyle(color: appColors.subtitle),
//                   prefixIcon: Icon(
//                     Icons.email_outlined,
//                     color: appColors.subtitle,
//                   ),
//                   filled: true,
//                   fillColor: appColors.surface,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(16),
//                     borderSide: BorderSide.none,
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(16),
//                     borderSide: BorderSide(
//                       color: appColors.divider ?? Colors.grey.shade200,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 40),
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   onPressed: auth.isLoading ? null : _resetPassword,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: appColors.primary,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: auth.isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           'Send Reset Link',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
