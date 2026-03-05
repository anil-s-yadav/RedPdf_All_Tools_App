// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import '../../domain/repositories/auth_repository.dart';

// class FirebaseAuthRepository implements AuthRepository {
//   FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

//   @override
//   Stream<User?> get authStateChanges {
//     try {
//       return _firebaseAuth.authStateChanges();
//     } catch (_) {
//       return Stream.value(null);
//     }
//   }

//   @override
//   User? get currentUser {
//     try {
//       return _firebaseAuth.currentUser;
//     } catch (_) {
//       return null;
//     }
//   }

//   @override
//   Future<UserCredential?> signInWithEmail(String email, String password) async {
//     return await _firebaseAuth.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//   }

//   @override
//   Future<UserCredential?> signUpWithEmail(String email, String password) async {
//     return await _firebaseAuth.createUserWithEmailAndPassword(
//       email: email,
//       password: password,
//     );
//   }

//   @override
//   Future<UserCredential?> signInWithGoogle() async {
//     // Note: ensure you have called initialize() in main or elsewhere if needed for web
//     final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

//     final GoogleSignInAuthentication googleAuth = googleUser.authentication;
//     final AuthCredential credential = GoogleAuthProvider.credential(
//       accessToken: null, // 7.2.0 emphasizes idToken for auth
//       idToken: googleAuth.idToken,
//     );

//     return await _firebaseAuth.signInWithCredential(credential);
//   }

//   @override
//   Future<void> signOut() async {
//     await _googleSignIn.signOut();
//     await _firebaseAuth.signOut();
//   }

//   @override
//   Future<void> sendPasswordResetEmail(String email) async {
//     await _firebaseAuth.sendPasswordResetEmail(email: email);
//   }
// }
