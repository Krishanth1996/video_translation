import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:top_modal_sheet/top_modal_sheet.dart';
import 'package:video_subtitle_translator/colors.dart';
import 'package:video_subtitle_translator/services/firebase_services.dart';
import '../constants.dart';
import '../login.dart';

void showProfileSheet(BuildContext context) async {
  AuthService authService = AuthService();
  await authService.initAuthService();
  String displayName = await authService.getDisplayName();
  String email = await authService.getEmail();
  String uid = await authService.getUid();

  Future<String?> getUserPhoneNumber(String? uid) async {
    if (uid == null) return null;

    try {
      User? user = await FirebaseAuth.instance.userChanges().first;
      if (user != null) {
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(
          PhoneAuthProvider.credential(
            verificationId: 'verificationId',
            smsCode: 'smsCode',
          ),
        );
        if (userCredential.user?.uid == uid) {
          return userCredential.user?.phoneNumber;
        }
      }
    } catch (e) {
      print('Error fetching phone number: $e');
    }
    return null;
  }

  String? phoneNumber = await getUserPhoneNumber(uid);

  // ignore: use_build_context_synchronously
  showTopModalSheet(
      context,
      Container(
        height: MediaQuery.of(context).size.height * 0.5,
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16.0),
        child: Container(
          margin: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(userProfileString,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor)),
                  IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: const Icon(Icons.close))
                ],
              ),
              const Divider(color: borderColor),
              const Text(emailString,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor)),
              const SizedBox(height: 5),
              Text(email, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 10),
              const Text(nameString,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor)),
              const SizedBox(height: 5),
              Text(displayName, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(phoneString,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor)),
                      const SizedBox(height: 5),
                      Text(
                        phoneNumber ?? noNumberMsg,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor),
                      onPressed: () {
                        showPhoneNoVerificationSheet(context);
                      },
                      child: const Text(verifyString)),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor),
                      child: const Text(deleteAccString))),
            ],
          ),
        ),
      ),
      barrierDismissible: false);
}

void showPhoneNoVerificationSheet(BuildContext context) {
  TextEditingController phoneNumberController = TextEditingController();
  Future<void> verifyPhoneNumber() async {
    String phoneNumber = phoneNumberController.text;
    try {
      if (phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Enter phone number'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 100,
                right: 20,
                left: 20),
          ),
        );
      } else {
        ConfirmationResult confirmationResult =
            await FirebaseAuth.instance.signInWithPhoneNumber(phoneNumber);

        UserCredential userCredential =
            await confirmationResult.confirm('smsCode');

        // Store the verified phone number in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .set({'phoneNumber': phoneNumber}, SetOptions(merge: true));

        // Navigate back to the profile screen or home screen
        Get.back();
      }
    } catch (e) {
      print('Error verifying phone number: $e');
    }
  }

  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    transitionDuration: const Duration(milliseconds: 500),
    barrierLabel: MaterialLocalizations.of(context).dialogLabel,
    barrierColor: Colors.black.withOpacity(0.5),
    pageBuilder: (context, _, __) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
            child: Card(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Verify Phone Number',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor),
                      ),
                      IconButton(
                          onPressed: () {
                            Get.back();
                          },
                          icon: const Icon(
                            Icons.close,
                            color: primaryColor,
                          ))
                    ],
                  ),
                  const Divider(
                    color: borderColor,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Enter your Phone Number here',
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primaryColor))),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                          onPressed: () {
                            verifyPhoneNumber();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor),
                          child: const Text('Verify'))),
                ],
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ).drive(Tween<Offset>(
          begin: const Offset(0, -1.0),
          end: Offset.zero,
        )),
        child: child,
      );
    },
  );
}

showLogoutAlertDialog(BuildContext context, String title, String message) {
  Widget okbtn = Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      TextButton(
          onPressed: () {
            Get.back();
          },
          child: const Text(cancelString,
              style: TextStyle(color: borderColor, fontSize: 18))),
      TextButton(
          onPressed: () async {
            await AuthService().signOut();
            Get.to(const Login());
          },
          child: const Text(confirmString,
              style: TextStyle(color: Colors.green, fontSize: 18))),
    ],
  );
  AlertDialog alert = AlertDialog(
    title:
        Center(child: Text(title, style: const TextStyle(color: primaryColor))),
    content: Text(message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: primaryColor)),
    actions: [okbtn],
  );
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      });
}

void showDownloadNowSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    builder: (BuildContext context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.4,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(confirmString,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryColor)),
                IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(Icons.close, color: primaryColor))
              ],
            ),
            const Divider(
              color: borderColor,
            ),
            const SizedBox(height: 10),
            const Text(askTranslateNowMsg,
                style: TextStyle(fontSize: 18, color: primaryColor)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                    onPressed: () {
                      showSubtitleSelectionSheet(
                        context,
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: const Text(yesString)),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: () {
                      Get.back();
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: const Text(cancelString)),
              ],
            ),
          ],
        ),
      );
    },
  );
}

void showSubtitleSelectionSheet(BuildContext context) {
  String selectedLanguage = 'en';
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    builder: (BuildContext context) {
      double width = MediaQuery.of(context).size.width;
      return Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(generateSubtitleMsg,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor)),
                IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: const Icon(Icons.close, color: primaryColor))
              ],
            ),
            const Divider(color: borderColor),
            const SizedBox(height: 20),
            const Text(selectTranslateLanguageMsg,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedLanguage,
              onChanged: (newValue) {
                setState() {
                  selectedLanguage = newValue!;
                }

                ;
              },
              decoration: InputDecoration(
                  filled: true,
                  hintText: selectLanguageMsg,
                  hintStyle: TextStyle(fontSize: width / 5 * 0.2),
                  prefixIcon: const Icon(Icons.language, color: primaryColor),
                  contentPadding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: primaryColor, width: 2)),
                  errorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  )),
              items: const [
                DropdownMenuItem<String>(
                  value: 'en',
                  child: Text('English'),
                ),
                DropdownMenuItem<String>(
                  value: 'fr',
                  child: Text('French'),
                ),
                DropdownMenuItem<String>(
                  value: 'de',
                  child: Text('German'),
                ),
                DropdownMenuItem<String>(
                  value: 'es',
                  child: Text('Spanish'),
                ),
              ],
            ),
            const Divider(color: borderColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                    onPressed: () {
                      // Home.extractAudioFromVideo();
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: primaryColor),
                    child: const Text(generateSubtitleString)),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: () {
                      Get.back();
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: borderColor),
                    child: const Text(closeString)),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: Text(translationMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: primaryColor)),
            ),
          ],
        ),
      );
    },
  );
}
