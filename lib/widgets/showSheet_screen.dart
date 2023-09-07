import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_subtitle_translator/colors.dart';
import 'package:video_subtitle_translator/services/firebase_services.dart';
import 'package:video_subtitle_translator/widgets/widgets.dart';
import '../constants.dart';
import '../login.dart';



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
                  onPressed: () {
                    Get.back();
                  },
                  backgroundColor: borderColor,
                  child: const Text(noString,
                      style: TextStyle(color: whiteColor, fontSize: 15))),
              ElevatedButtonWidget(
                  onPressed: () async {
                    await AuthService().signOut();
                    Get.to(const Login());
                  },
                  backgroundColor: primaryColor,
                  child: const Text(yesString,
                      style: TextStyle(color: whiteColor, fontSize: 15))),
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

bool isVideoPlaying=false;

void showDeleteAccount(BuildContext context) async {
  AuthService authService = AuthService();
  await authService.initAuthService();
  // ignore: use_build_context_synchronously
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          'Delete your Account?',
          style: TextStyle(color: primaryColor),
        ),
        content: const Text(
            "If you select Delete we will delete your account on our server.\n\nYour app data will also be deleted and you won't be able to retrieve it.",
            style: TextStyle(color: primaryColor)),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: borderColor),
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text(
                  'Delete',
                ),
                onPressed: () async {
                  await authService.deleteAccount();
                  Get.snackbar('Your Account Deleted', 'Successfully',backgroundColor: redColor.withOpacity(0.2),snackPosition: SnackPosition.TOP,titleText: const Text('Your Account Deleted', style: TextStyle(color: redColor)));
                },
              ),
            ],
          ),
        ],
      );
    },
  );
}

void showProfileSheet(BuildContext context) async {
  AuthService authService = AuthService();
  await authService.initAuthService();
  String displayName = await authService.getDisplayName();
  String email = await authService.getEmail();

  // String phone = await authService.getUpdatePhoneNo();
  String phoneNo = await authService.getPhoneNo();
  bool? isGoogleLogin = await authService.getGoogleLogin();
  // ignore: use_build_context_synchronously
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    builder: (BuildContext context) {
      double width = MediaQuery.of(context).size.width;
      double height = MediaQuery.of(context).size.height;
      return Container(
        height: MediaQuery.of(context).size.height * 0.4,
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16.0),
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              if (isGoogleLogin == true)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // CircleAvatar(
                        //   radius:20, // Adjust the size of the circle as needed
                        //   backgroundImage: NetworkImage(photo ?? ''),
                        // ),
                        const Text(userProfileString,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryColor)),
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
                    // const SizedBox(height: 10),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Column(
                    //       mainAxisAlignment: MainAxisAlignment.start,
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         const Text(phoneString,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: primaryColor)),
                    //         const SizedBox(height: 5),
                    //         Text(existingPhoneNumber.isNotEmpty ? existingPhoneNumber : phone, style: const TextStyle(fontSize: 15)),
                    //       ],
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 10),
                  ],
                ),
              if (isGoogleLogin == false)
                Column(
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
                            icon: const Icon(
                              Icons.close,
                              color: primaryColor,
                            ))
                      ],
                    ),
                    const Divider(color: borderColor),
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
                            Text(phoneNo, style: const TextStyle(fontSize: 15)),
                            // const SizedBox(height: 10),
                            // const Text(emailString,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: primaryColor)),
                            // const SizedBox(height: 5),
                            // Text(email, style: const TextStyle(fontSize: 15)),
                            // const SizedBox(height: 10)
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                            onPressed: () async {
                              await authService.deletePhoneNumberAccount();
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor),
                            child: const Text(deleteAccString))),
                  ],
                ),
            ],
          ),
        ),
      );
    },
  );
}


