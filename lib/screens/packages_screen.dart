// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:redpdf_tools/theme/app_theme.dart';
// import '../providers/auth_provider.dart';
// import 'login_screen.dart';

// class PackagesScreen extends StatefulWidget {
//   const PackagesScreen({super.key});

//   @override
//   State<PackagesScreen> createState() => _PackagesScreenState();
// }

// class _PackagesScreenState extends State<PackagesScreen> {
//   bool _freeTrialEnabled = true;

//   @override
//   Widget build(BuildContext context) {
//     final appColors = Theme.of(context).appColors;

//     return Scaffold(
//       backgroundColor: appColors.background,
//       appBar: AppBar(
//         backgroundColor: appColors.background,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: appColors.text),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           'Go Pro',
//           style: TextStyle(color: appColors.text, fontWeight: FontWeight.bold),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Top Premium Banner
//             Container(
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [Color(0xFFF97316), Color(0xFFEF4444)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.red.withOpacity(0.2),
//                     blurRadius: 15,
//                     offset: const Offset(0, 8),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: const Text(
//                       'PREMIUM MEMBERSHIP',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 10,
//                         letterSpacing: 1.0,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Remove Ads &\nConvert Unlimited\nPDFs',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       height: 1.2,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Get 100 days of Pro features for FREE\nwhen you sign in today!',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.9),
//                       fontSize: 14,
//                       height: 1.5,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Free Trial Toggle
//             Container(
//               margin: const EdgeInsets.symmetric(horizontal: 16),
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//               decoration: BoxDecoration(
//                 color: appColors.surface,
//                 borderRadius: BorderRadius.circular(30),
//                 border: Border.all(color: Colors.grey.shade200),
//               ),
//               child: Row(
//                 children: [
//                   const Expanded(
//                     child: Text(
//                       'Start with 100-day Free Trial',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 15,
//                       ),
//                     ),
//                   ),
//                   Switch(
//                     value: _freeTrialEnabled,
//                     onChanged: (v) => setState(() => _freeTrialEnabled = v),
//                     activeThumbColor: Colors.orange,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Recommended for new users',
//               style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
//             ),

//             const SizedBox(height: 24),

//             // Monthly Plan
//             _buildPlanCard(
//               title: 'Monthly',
//               price: '₹149',
//               period: '/ Month',
//               features: [
//                 'Unlimited conversions',
//                 'No intrusive ads',
//                 'Priority customer support',
//               ],
//               buttonLabel: 'Start My Free Trial',
//               isPopular: false,
//               appColors: appColors,
//             ),

//             const SizedBox(height: 16),

//             // Yearly Plan
//             _buildPlanCard(
//               title: 'Yearly',
//               price: '₹399',
//               period: '/ Year',
//               features: [
//                 'Everything in Monthly, plus:',
//                 'Password protection for PDFs',
//                 'Automatic cloud backup',
//                 'Early access to new features',
//               ],
//               buttonLabel: 'Start My Free Trial',
//               isPopular: true,
//               tag: 'BEST VALUE - SAVE 77%',
//               appColors: appColors,
//             ),

//             const SizedBox(height: 32),

//             // Free Tier Description
//             Container(
//               margin: const EdgeInsets.symmetric(horizontal: 16),
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: appColors.surface,
//                 borderRadius: BorderRadius.circular(24),
//                 border: Border.all(
//                   color: appColors.divider ?? Colors.grey.shade100,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Free / Guest Tier',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 12),
//                   _buildFreeFeatureRow(
//                     Icons.check_circle_outline,
//                     'Access to all PDF tools',
//                   ),
//                   _buildFreeFeatureRow(
//                     Icons.timer_outlined,
//                     'Limited to 5 actions per day',
//                   ),
//                   _buildFreeFeatureRow(
//                     Icons.ads_click,
//                     'Contains advertisements',
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Sign in now to unlock your 100-day Pro trial!',
//                     style: TextStyle(
//                       color: Color(0xFFF97316),
//                       fontWeight: FontWeight.bold,
//                       fontSize: 13,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 48),
//             const Text(
//               'Why go Premium?',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 24),

//             _buildFeatureItem(
//               icon: Icons.all_inclusive,
//               title: 'Unlimited Conversions',
//               subtitle:
//                   'No daily limits. Convert hundreds of files in seconds.',
//               appColors: appColors,
//             ),
//             _buildFeatureItem(
//               icon: Icons.block,
//               title: 'Ad-Free Experience',
//               subtitle:
//                   'Focus on your work without annoying popup interruptions.',
//               appColors: appColors,
//             ),
//             _buildFeatureItem(
//               icon: Icons.security,
//               title: 'Secure Protection',
//               subtitle:
//                   'Encrypt your documents with enterprise-grade security.',
//               appColors: appColors,
//             ),

//             const SizedBox(height: 48),

//             // Footer
//             Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(4),
//                       decoration: BoxDecoration(
//                         color: Colors.orange,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Icon(
//                         Icons.picture_as_pdf,
//                         color: Colors.white,
//                         size: 20,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     const Text(
//                       'PDF Converter Pro',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     _buildFooterLink('Terms of Service'),
//                     _buildFooterDivider(),
//                     _buildFooterLink('Privacy Policy'),
//                     _buildFooterDivider(),
//                     _buildFooterLink('Refund Policy'),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 const Text(
//                   '© 2024 PDF Converter App. All rights reserved.',
//                   style: TextStyle(color: Colors.grey, fontSize: 12),
//                 ),
//                 const SizedBox(height: 40),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPlanCard({
//     required String title,
//     required String price,
//     required String period,
//     required List<String> features,
//     required String buttonLabel,
//     bool isPopular = false,
//     String? tag,
//     required AppColors appColors,
//   }) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: BoxDecoration(
//         color: appColors.surface,
//         borderRadius: BorderRadius.circular(24),
//         border: Border.all(
//           color: isPopular ? Colors.orange : Colors.grey.shade200,
//           width: isPopular ? 2 : 1,
//         ),
//         boxShadow: isPopular
//             ? [
//                 BoxShadow(
//                   color: Colors.orange.withOpacity(0.1),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ]
//             : [],
//       ),
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           if (tag != null)
//             Positioned(
//               top: -12,
//               left: 40,
//               right: 40,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.shade800,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Center(
//                   child: Text(
//                     tag,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 10,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     if (isPopular)
//                       const Icon(Icons.star, color: Colors.orange, size: 24),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.baseline,
//                   textBaseline: TextBaseline.alphabetic,
//                   children: [
//                     Text(
//                       price,
//                       style: const TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       period,
//                       style: const TextStyle(color: Colors.grey, fontSize: 16),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 2,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.orange.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: const Text(
//                     'TRIAL AVAILABLE',
//                     style: TextStyle(
//                       color: Colors.orange,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 10,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 const Text(
//                   'Flexible commitment, cancel anytime.',
//                   style: TextStyle(color: Colors.grey, fontSize: 13),
//                 ),
//                 const SizedBox(height: 20),
//                 ...features.map(
//                   (f) => Padding(
//                     padding: const EdgeInsets.only(bottom: 8),
//                     child: Row(
//                       children: [
//                         const Icon(
//                           Icons.check_circle,
//                           color: Colors.orange,
//                           size: 18,
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(f, style: const TextStyle(fontSize: 14)),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       final authProvider = Provider.of<AuthProvider>(
//                         context,
//                         listen: false,
//                       );
//                       if (!authProvider.isAuthenticated) {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const LoginScreen(),
//                           ),
//                         );
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text(
//                               'Plan activation is handled by the administrator. Please contact support.',
//                             ),
//                             backgroundColor: Colors.orange,
//                           ),
//                         );
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: isPopular
//                           ? Colors.orange.shade800
//                           : Colors.orange.shade50,
//                       foregroundColor: isPopular
//                           ? Colors.white
//                           : Colors.orange.shade800,
//                       elevation: 0,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                     ),
//                     child: Text(
//                       buttonLabel,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFeatureItem({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required AppColors appColors,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.orange.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: Colors.orange, size: 32),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             title,
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             subtitle,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               color: Colors.grey,
//               fontSize: 14,
//               height: 1.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFreeFeatureRow(IconData icon, String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         children: [
//           Icon(icon, size: 18, color: Colors.grey),
//           const SizedBox(width: 12),
//           Text(text, style: const TextStyle(color: Colors.grey, fontSize: 14)),
//         ],
//       ),
//     );
//   }

//   Widget _buildFooterLink(String label) {
//     return Text(
//       label,
//       style: const TextStyle(
//         color: Colors.blueGrey,
//         fontSize: 12,
//         fontWeight: FontWeight.w500,
//       ),
//     );
//   }

//   Widget _buildFooterDivider() {
//     return const Padding(
//       padding: EdgeInsets.symmetric(horizontal: 8),
//       child: Text('|', style: TextStyle(color: Colors.grey, fontSize: 12)),
//     );
//   }
// }
