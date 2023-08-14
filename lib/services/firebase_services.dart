// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   // Sign in with Google
//   Future<User?> signInWithGoogle() async {
//     try {
//       // Trigger the Google Sign In process
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

//       if (googleUser == null) return null;

//       // Obtain the GoogleSignInAuthentication object
//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       // Create a new credential using the GoogleSignInAuthentication object
//       final AuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       // Sign in to Firebase with the Google credentials
//       final UserCredential authResult =
//           await _auth.signInWithCredential(credential);
//       print(authResult.user);
//       User? user = authResult.user;
//       if (user != null) {
//         print("User Name: ${user.displayName}");
//         print("User Email ${user.email}");
//         print("User Id ${user.uid}");
//       }
//       return authResult.user;
//     } catch (error) {
//       print("Error signing in with Google: $error");
//       return null;
//     }
//   }

//   Future<void> signOut() async {
//     final GoogleSignIn _googleSignIn = GoogleSignIn();
//     final FirebaseAuth _auth = FirebaseAuth.instance;

//     try {
//       // Sign out from Firebase
//       await _auth.signOut();

//       // Sign out from Google
//       await _googleSignIn.signOut();

//       print("User signed out successfully.");
//     } catch (error) {
//       print("Error signing out: $error");
//     }
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_subtitle_translator/home.dart';
import 'package:video_subtitle_translator/otp_scree.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  SharedPreferences? _prefs;
  String phoneNumber = "";
  String verificationId = "";

  AuthService() {
    initAuthService(); // Initialize AuthService and SharedPreferences
  }

  Future<void> initAuthService() async {
    await initSharedPreferences();
  }

  Future<void> initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool isUserLoggedIn() {
    final User? user = _auth.currentUser;
    return user != null;
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign In process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) return null;

      // Obtain the GoogleSignInAuthentication object
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential using the GoogleSignInAuthentication object
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final UserCredential authResult =
          await _auth.signInWithCredential(credential);

      User? user = authResult.user;
      if (user != null) {
        // Save user data to SharedPreferences
        await _prefs?.setString('displayName', user.displayName ?? '');
        await _prefs?.setString('email', user.email ?? '');
        await _prefs?.setString('uid', user.uid);
        Get.offAll(const Home());
      }
      print(user?.displayName);
      print(user?.email);

      if (AuthService().isUserLoggedIn()) {
        // Navigate to home screen
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          Get.offAll(const Home());
        });
      }

      return authResult.user;
    } catch (error) {
      print("Error signing in with Google: $error");
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _auth.signOut();

      // Sign out from Google
      await _googleSignIn.signOut();

      // Clear user data from SharedPreferences
      await _prefs?.remove('displayName');
      await _prefs?.remove('email');
      await _prefs?.remove('uid');

      print("User signed out successfully.");
    } catch (error) {
      print("Error signing out: $error");
    }
  }

  // Get user data from SharedPreferences
  Future<String> getDisplayName() async {
    return _prefs?.getString('displayName') ?? '';
  }

  Future<String> getEmail() async {
    return _prefs?.getString('email') ?? '';
  }

  Future<String> getUid() async {
    return _prefs?.getString('uid') ?? '';
  }

  Future<void> verifyPhoneNumber(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Verification Failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          verificationId = verificationId;
          Get.to(OTPVerificationScreen(phoneNumber,verificationId));
          // Get.to(OTPVerificationScreen(verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Called when the automatic code retrieval process times out
        },
      );
    } catch (error) {
      print("Error verifying phone number: $error");
    }
  }

  Future<void> submitOTP(String otp) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;
      if (user != null) {
        await _prefs?.setString('uid', user.uid);
      }
    } catch (error) {
      print("Error submitting OTP: $error");
    }
  }
}
