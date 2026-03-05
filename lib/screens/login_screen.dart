// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../theme/app_theme.dart';
// import 'signup_screen.dart';
// import 'forgot_password_screen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscurePassword = true;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _login() async {
//     final auth = context.read<AuthProvider>();
//     try {
//       await auth.signInWithEmail(
//         _emailController.text.trim(),
//         _passwordController.text.trim(),
//       );
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   Future<void> _loginWithGoogle() async {
//     final auth = context.read<AuthProvider>();
//     try {
//       await auth.signInWithGoogle();
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
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 40),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: appColors.primary!.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: Icon(
//                   Icons.picture_as_pdf,
//                   color: appColors.primary,
//                   size: 40,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 'Welcome Back!',
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: appColors.text,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Sign in to access your premium PDF tools.',
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
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: TextButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const ForgotPasswordScreen(),
//                       ),
//                     );
//                   },
//                   child: Text(
//                     'Forgot Password?',
//                     style: TextStyle(
//                       color: appColors.primary,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   onPressed: auth.isLoading ? null : _login,
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
//                           'Sign In',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 children: [
//                   Expanded(child: Divider(color: appColors.divider)),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: Text(
//                       'OR',
//                       style: TextStyle(color: appColors.subtitle, fontSize: 12),
//                     ),
//                   ),
//                   Expanded(child: Divider(color: appColors.divider)),
//                 ],
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: OutlinedButton.icon(
//                   onPressed: auth.isLoading ? null : _loginWithGoogle,
//                   icon: Image.network(
//                     'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/500px-Google_%22G%22_logo.svg.png',
//                     height: 20,
//                     errorBuilder: (context, error, stackTrace) =>
//                         const Icon(Icons.g_mobiledata, size: 30),
//                   ),
//                   label: Text(
//                     'Continue with Google',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: appColors.text,
//                     ),
//                   ),
//                   style: OutlinedButton.styleFrom(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     side: BorderSide(
//                       color: appColors.divider ?? Colors.grey.shade200,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 40),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     "Don't have an account? ",
//                     style: TextStyle(color: appColors.subtitle),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const SignupScreen()),
//                       );
//                     },
//                     child: Text(
//                       'Sign Up',
//                       style: TextStyle(
//                         color: appColors.primary,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
