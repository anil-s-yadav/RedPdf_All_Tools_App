// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../theme/app_theme.dart';

// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscurePassword = true;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _signup() async {
//     final auth = context.read<AuthProvider>();
//     try {
//       await auth.signUpWithEmail(
//         _emailController.text.trim(),
//         _passwordController.text.trim(),
//         _nameController.text.trim(),
//       );
//       if (mounted) Navigator.pop(context);
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
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Create Account',
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: appColors.text,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Join us to manage and convert your PDF professionally.',
//                 style: TextStyle(fontSize: 16, color: appColors.subtitle),
//               ),
//               const SizedBox(height: 40),
//               TextField(
//                 controller: _nameController,
//                 style: TextStyle(color: appColors.text),
//                 decoration: InputDecoration(
//                   labelText: 'Full Name',
//                   labelStyle: TextStyle(color: appColors.subtitle),
//                   prefixIcon: Icon(
//                     Icons.person_outline,
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
//               const SizedBox(height: 20),
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
//               const SizedBox(height: 20),
//               TextField(
//                 controller: _passwordController,
//                 obscureText: _obscurePassword,
//                 style: TextStyle(color: appColors.text),
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   labelStyle: TextStyle(color: appColors.subtitle),
//                   prefixIcon: Icon(
//                     Icons.lock_outline,
//                     color: appColors.subtitle,
//                   ),
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscurePassword
//                           ? Icons.visibility_off
//                           : Icons.visibility,
//                       color: appColors.subtitle,
//                     ),
//                     onPressed: () =>
//                         setState(() => _obscurePassword = !_obscurePassword),
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
//                   onPressed: auth.isLoading ? null : _signup,
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
//                           'Create Account',
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
