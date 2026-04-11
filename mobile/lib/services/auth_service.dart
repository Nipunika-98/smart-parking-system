import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login
  Future<UserCredential> loginUser(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Change Password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");
      if (user.email == null) throw Exception("User has no email");
      
      // Re-authenticate user before changing password
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!, 
        password: currentPassword
      );
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  // Register User
  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    bool saveToFirestore = true,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      if (result.user == null) throw Exception('User creation failed');

      UserModel newUser = UserModel(
        userId: result.user!.uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        registrationDate: DateTime.now(),
        isActive: true,
      );
      
      if (saveToFirestore) {
        await createUserProfile(newUser);
      }
      
      return newUser;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Create user profile in Firestore
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.userId).set(user.toJson());
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Fetch user profile
  Future<UserModel> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) throw Exception('User profile not found');
      return UserModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // // Register Admin (Optional, usually done via backend)
  // Future<UserCredential> registerAdmin({
  //   required String name,
  //   required String email,
  //   required String password,
  // }) async {
  //   try {
  //     UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
  //     if (result.user != null) {
  //       AdminModel newAdmin = AdminModel(
  //         adminId: result.user!.uid,
  //         adminName: name,
  //         email: email,
  //         role: 'admin',
  //         registrationDate: DateTime.now(),
  //       );
        
  //       await _firestore.collection('admins').doc(result.user!.uid).set(newAdmin.toJson());
  //     }
  //     return result;
  //   } catch (e) {
  //     throw Exception('Admin registration failed: $e');
  //   }
  // }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore errors signing out of Google if not logged in with it
    }
    await _auth.signOut();
  }

  // Sign In with Google
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In aborted by user');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed');
      }

      // Check if user exists in Firestore
      try {
        await getUserProfile(firebaseUser.uid);
        return false; // Not their first time
      } catch (e) {
        // User does not exist, create a new profile
        UserModel newUser = UserModel(
          userId: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Google User',
          email: firebaseUser.email ?? '',
          phoneNumber: firebaseUser.phoneNumber ?? '',
          registrationDate: DateTime.now(),
          isActive: true,
          isFirstLogin: true, 
        );
        await createUserProfile(newUser);
        return true; // First time login!
      }
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
    }
  }
}
