import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_subtitle_translator/home.dart';
import 'package:video_subtitle_translator/login.dart';
import 'package:video_subtitle_translator/otp_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SharedPreferences? _prefs;
  String verificationId = '';
  String smsCode = "";

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
  Future<User?> signInWithGoogle(String phoneNumber) async {
    try {
      // Trigger the Google Sign In process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtain the GoogleSignInAuthentication object
      final GoogleSignInAuthentication googleAuth =await googleUser.authentication;

      // Create a new credential using the GoogleSignInAuthentication object
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final UserCredential authResult =await _auth.signInWithCredential(credential);

      User? user = authResult.user;
      if (user != null) {
        // Save user data to SharedPreferences
        await _prefs?.setString('displayName', user.displayName ?? '');
        await _prefs?.setString('email', user.email ?? '');
        await _prefs?.setString('uid', user.uid);

        // if (phoneNumber.isNotEmpty) {
        //   await user.updatePhoneNumber(PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode));
        //   await _prefs?.setString('phoneNo', phoneNumber);
        // }
      }
      print(user?.displayName);
      print(user?.email);

      if (AuthService().isUserLoggedIn()) {
        // Navigate to home screen
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          Get.to(const Home());
        });
      }
      return authResult.user;
    } 
    catch (error) {
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
      await _prefs?.remove('phoneNo');

      print("User signed out successfully.");
    } 
    catch (error) {
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

  Future<String> getPhoneNo() async {
    return _prefs?.getString('phoneNo') ?? '';
  }

  Future<String> getUpdatePhoneNo() async {
    try {
      String uid = _auth.currentUser!.uid;
      DocumentSnapshot snapshot =
          await _firestore.collection('users').doc(uid).get();
      return snapshot.get('phoneNo');
    } catch (error) {
      print('Error getting phone number: $error');
      return '';
    }
  }

  Future<String> getUpdateEmail() async {
    try {
      String uid = _auth.currentUser!.uid;
      DocumentSnapshot snapshot =
          await _firestore.collection('users').doc(uid).get();
      return snapshot.get('email');
    } catch (error) {
      print('Error getting email address: $error');
      return '';
    }
  }

  Future<void> verifyPhoneNumber(String phoneNo) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNo,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
           print('Phone number automatically verified and user signed in.');
        },
        verificationFailed: (FirebaseAuthException e) {
          if (e.code == 'invalid-phone-number') {
            Get.snackbar('Error', 'The provided phone numbet is not valid');
          } else {
            Get.snackbar('Error', 'Something went wrong. Try again');
            Get.to(const Login());
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          verificationId = verificationId;
          Get.to(OTPVerificationScreen(phoneNo, verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          verificationId = verificationId;
          // Called when the automatic code retrieval process times out
        },
      );
    } catch (error) {
      print("Error verifying phone number: $error");
    }
  }

  Future<void> submitOTP(String otp, String verificationId) async {
    try {
      if (verificationId == null) {
        throw Exception("Verification ID is null");
      } else {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: otp,
        );

        UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        User? user = userCredential.user;
        if (user != null) {
          await _prefs?.setString('phoneNo', user.phoneNumber ?? '');
          Get.to(const Home());
        } else {
          throw Exception("Failed to sign in with OTP");
        }
      }
    } catch (error) {
      print("Error submitting OTP: $error");
      Get.to(const Login());
    }
  }

  Future<void> savePhoneNo(String phoneNo) async {
    try {
      String uid = _auth.currentUser!.uid;
      // String? uemail = _auth.currentUser!.email;

      // Check if user already has a phone number
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.get('phoneNo') != null) {
        // User already has a phone number, retrieve it from Firebase
        String existingPhoneNumber = userDoc.get('phoneNo');
        print('Phone number already exists for this user');
        Get.snackbar(
            'Notification', 'Phone number already exists for this user');
      } else {
        // Save the number if not already exists
        await _firestore.collection('users').doc(uid).set({
          'phoneNo': phoneNo,
        }, SetOptions(merge: true));
        DocumentSnapshot snapshot =
            await _firestore.collection('users').doc(uid).get();
        // return snapshot.get('phoneNo');
        // Get.snackbar('', 'Phone number successfully updated');
        await _prefs?.setString('phoneNo', phoneNo);
      }
    } catch (error) {
      print('Error saving phone number: $error');
    }
  }

  Future<void> saveEmail(String email) async {
    try {
      String uid = _auth.currentUser!.uid;

      // Check if user already has a email address
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.get('email') != null) {
        // User already has a email address, retrieve it from Firebase
        String existingEmail = userDoc.get('email');
        print('Email Address already exists for this user');
        Get.snackbar(
            'Notification', 'Email Address already exists for this user');
      } else {
        // Save the email address if not already exists
        await _firestore.collection('users').doc(uid).set({
          'email': email,
        }, SetOptions(merge: true));
        DocumentSnapshot snapshot =
            await _firestore.collection('users').doc(uid).get();

        await _prefs?.setString('email', email);
      }
    } catch (error) {
      print('Error saving Email Address: $error');
    }
  }
}
