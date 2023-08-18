import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:top_modal_sheet/top_modal_sheet.dart';
import 'package:video_subtitle_translator/colors.dart';
import 'package:video_subtitle_translator/services/firebase_services.dart';
import 'package:video_subtitle_translator/widgets/widgets.dart';
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

  Future<void> showLogoutAlertDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                attemptLogoutString,
                style: TextStyle(color: primaryColor, fontSize: 20),
              ),
              Divider(color: borderColor),
              Text(
                askLogoutMsg,
                style: TextStyle(color: primaryColor, fontSize: 16),
              )
            ],
          ),
          actions: <Widget>[
            Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButtonWidget(
                  onPressed: (){
                    Get.back();
                  }, 
                  backgroundColor: borderColor,
                  child: const Text(noString,style: TextStyle(color: whiteColor, fontSize: 15))
                ),
                ElevatedButtonWidget(
                  onPressed: () async{
                   await AuthService().signOut();
                    Get.to(const Login());
                  }, 
                  backgroundColor: primaryColor,
                  child: const Text(yesString,style: TextStyle(color: whiteColor, fontSize: 15))
                ),
              ],
            ),
            
          ],
        );
      },
    );
  }

  void showLimitAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Monthly Limit Reached'),
          content: const Text('You have reached your monthly usage limit.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(okString),
            ),
          ],
        );
      },
    );
  }