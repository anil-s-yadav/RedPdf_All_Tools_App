// import 'package:cloud_firestore/cloud_firestore.dart';

// class UserModel {
//   final String id;
//   final String email;
//   final String? displayName;
//   final String? photoUrl;
//   final DateTime trialStartDate;
//   final bool isPremium;
//   final int dailyConversionCount;
//   final DateTime lastConversionDate;

//   UserModel({
//     required this.id,
//     required this.email,
//     this.displayName,
//     this.photoUrl,
//     required this.trialStartDate,
//     this.isPremium = false,
//     this.dailyConversionCount = 0,
//     required this.lastConversionDate,
//   });

//   factory UserModel.fromMap(Map<String, dynamic> map, String id) {
//     return UserModel(
//       id: id,
//       email: map['email'] ?? '',
//       displayName: map['displayName'],
//       photoUrl: map['photoUrl'],
//       trialStartDate: (map['trialStartDate'] as Timestamp).toDate(),
//       isPremium: map['isPremium'] ?? false,
//       dailyConversionCount: map['dailyConversionCount'] ?? 0,
//       lastConversionDate: (map['lastConversionDate'] as Timestamp).toDate(),
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'email': email,
//       'displayName': displayName,
//       'photoUrl': photoUrl,
//       'trialStartDate': trialStartDate,
//       'isPremium': isPremium,
//       'dailyConversionCount': dailyConversionCount,
//       'lastConversionDate': lastConversionDate,
//     };
//   }

//   int get remainingTrialDays {
//     final now = DateTime.now();
//     final trialEnd = trialStartDate.add(const Duration(days: 100));
//     final difference = trialEnd.difference(now).inDays;
//     return difference > 0 ? difference : 0;
//   }

//   bool get isTrialActive => remainingTrialDays > 0;

//   bool get hasPremiumAccess => isPremium || isTrialActive;
// }
