// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../domain/models/user_model.dart';
// import '../../domain/repositories/user_repository.dart';

// class FirebaseUserRepository implements UserRepository {
//   FirebaseFirestore get _firestore => FirebaseFirestore.instance;
//   final String _collection = 'users';

//   @override
//   Future<void> createUser(UserModel user) async {
//     await _firestore.collection(_collection).doc(user.id).set(user.toMap());
//   }

//   @override
//   Future<UserModel?> getUser(String id) async {
//     final doc = await _firestore.collection(_collection).doc(id).get();
//     if (!doc.exists) return null;
//     return UserModel.fromMap(doc.data()!, id);
//   }

//   @override
//   Future<void> updateUser(UserModel user) async {
//     await _firestore.collection(_collection).doc(user.id).update(user.toMap());
//   }

//   @override
//   Future<void> incrementConversionCount(String id) async {
//     final docRef = _firestore.collection(_collection).doc(id);
//     final doc = await docRef.get();

//     if (doc.exists) {
//       final data = doc.data()!;
//       final lastDate = (data['lastConversionDate'] as Timestamp).toDate();
//       final now = DateTime.now();

//       // Reset count if it's a new day
//       if (lastDate.day != now.day ||
//           lastDate.month != now.month ||
//           lastDate.year != now.year) {
//         await docRef.update({
//           'dailyConversionCount': 1,
//           'lastConversionDate': now,
//         });
//       } else {
//         await docRef.update({
//           'dailyConversionCount': FieldValue.increment(1),
//           'lastConversionDate': now,
//         });
//       }
//     }
//   }
// }
