import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:top_modal_sheet/top_modal_sheet.dart';
import 'package:video_subtitle_translator/colors.dart';
import 'package:video_subtitle_translator/services/firebase_services.dart';
import '../constants.dart';
import '../login.dart';

void showProfileSheet(BuildContext context) async {
  AuthService authService = AuthService();
  LoginMethod loginMethod = LoginMethod.google;
  await authService.initAuthService();
  String displayName = await authService.getDisplayName();
  String email = await authService.getEmail();
  String uid = await authService.getUid();
  String phone = await authService.getUpdatePhoneNo();
  String phoneNo = await authService.getPhoneNo();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String existingPhoneNumber = '';
  //  if(loginMethod== LoginMethod.Google){

  // DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
  // if (userDoc.exists && userDoc.get('phoneNo') != null) {
  //   existingPhoneNumber = userDoc.get('phoneNo');
  // }
  //  } // Initialize with an empty string


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
              if(loginMethod== LoginMethod.google)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(userProfileString,style: TextStyle(fontSize: 22,fontWeight: FontWeight.bold,color: primaryColor)),
                  IconButton(onPressed: () {Get.back();},icon: const Icon(Icons.close))
                ],
              ),
              const Divider(color: borderColor),
              const Text(emailString,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: primaryColor)),
              const SizedBox(height: 5),
              Text(email, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 10),
              const Text(nameString,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: primaryColor)),
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
                      const Text(phoneString,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: primaryColor)),
                      const SizedBox(height: 5),
                      Text(existingPhoneNumber.isNotEmpty ? existingPhoneNumber : phone, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ],
              ),
              if(loginMethod== LoginMethod.phoneNumber)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:  [
                      const Text(phoneString,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: primaryColor)),
                      const SizedBox(height: 5),
                      Text(phoneNo,style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 10),
                      const Text(emailString,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: primaryColor)),
                      const SizedBox(height: 5),
                      Text(email, style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 10)
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),child: const Text(deleteAccString)
                )
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false);
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