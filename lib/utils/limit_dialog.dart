// import 'package:flutter/material.dart';
// import 'package:redpdf_tools/theme/app_theme.dart';
// import '../screens/packages_screen.dart';
// import '../screens/login_screen.dart';

// void showLimitReachedDialog(BuildContext context, bool isAuthenticated) {
//   final appColors = Theme.of(context).appColors;

//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//       title: Row(
//         children: [
//           Icon(Icons.warning_amber_rounded, color: appColors.primary),
//           const SizedBox(width: 8),
//           const Text('Limit Reached'),
//         ],
//       ),
//       content: Text(
//         isAuthenticated
//             ? 'You have reached your daily limit of 5 conversions. Upgrade to Pro for unlimited access!'
//             : 'Guests are limited to 5 conversions per day. Sign in now to unlock a 100-day FREE Pro trial!',
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: Text(
//             'Maybe Later',
//             style: TextStyle(color: appColors.subtitle),
//           ),
//         ),
//         ElevatedButton(
//           onPressed: () {
//             Navigator.pop(context);
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => isAuthenticated
//                     ? const PackagesScreen()
//                     : const LoginScreen(),
//               ),
//             );
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: appColors.primary,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//           child: Text(
//             isAuthenticated ? 'Upgrade' : 'Sign In',
//             style: const TextStyle(color: Colors.white),
//           ),
//         ),
//       ],
//     ),
//   );
// }
