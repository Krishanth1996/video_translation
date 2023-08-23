import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_subtitle_translator/colors.dart';
import 'package:video_subtitle_translator/constants.dart';
import 'package:video_subtitle_translator/services/firebase_services.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool passwordVisible = true;
  bool isLoading = false;
  bool showOverlay = false;
  bool isShowMissingEntriesSheet = true;
  bool isPhoneLogin = false;

  String phoneNumber = "";
  String updatePhoneNo = "";
  String email = "";
  String verificationId = '';
  String smsCode = '';

  TextEditingController phoneNoController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  AuthService authService = AuthService();
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    authService.initSharedPreferences();
  }

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Future<void> checkExistNumber() async {
  //   String uid = _auth.currentUser!.uid;
  //   DocumentSnapshot userDoc =await _firestore.collection('users').doc(uid).get();
  //   if (userDoc.exists && userDoc.get('phoneNo') != null) {
  //     setState(() {
  //       isShowMissingEntriesSheet = false; // User has a phone number
  //     });
  //   } else {
  //     setState(() {
  //       isShowMissingEntriesSheet =true; // User does not have a phone number
  //     });
  //   }
  // }

  // Future<void> checkExistEmail() async {
  //   String uid = _auth.currentUser!.uid;
  //   DocumentSnapshot userDoc =await _firestore.collection('users').doc(uid).get();
  //   if (userDoc.exists && userDoc.get('email') != null) {
  //     setState(() {
  //       isShowMissingEntriesSheet = false; // User has a phone number
  //     });
  //   } else {
  //     setState(() {
  //       isShowMissingEntriesSheet =true; // User does not have a phone number
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: primaryColor,
        body: Stack(
          children: [
            Container(
              height: height / 0.55,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50))),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: height / 3),
                    Image.asset(logoImg, height: height / 1.25),
                    //Phone Number Field//
                    TextFormField(
                      controller: phoneNoController,
                      keyboardType: TextInputType.phone,
                      onChanged: (value) {
                        setState(() {
                          phoneNumber = value;
                        });
                      },
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.phone),
                          hintText: phoneNoString,
                          hintStyle: TextStyle(color: Colors.black),
                          enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20))),
                          focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)))),
                    ),
                    const SizedBox(height: 20.0),
                    //Login Submit Button Field//
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20))),
                          padding: const EdgeInsets.all(15)),
                      onPressed: () async {
                        authService
                            .verifyPhoneNumber(phoneNoController.text.trim());

                      },
                      child: const Text(loginString,
                          style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(height: 20),
                    //Google Login Field//
                    GestureDetector(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(googleImg, height: 30, width: 30),
                          const SizedBox(width: 10),
                          const Text(signInGoogleString,
                              style: TextStyle(fontSize: 16))
                        ],
                      ),
                      onTap: () async {
                        setState(() {
                          isLoading = true; // Start loading
                        });
                        AuthService authService = AuthService();
                        await authService.initAuthService();
                        User? user = await AuthService().signInWithGoogle(phoneController.text);

                        setState(() async {
                          isLoading = false; // Stop loading
                          if (user != null) {
                            showOverlay = true; // Show the overlay
                            Future.delayed(const Duration(seconds: 2),
                                () async {
                              setState(() {
                                showOverlay = false;
                              });
                              // await checkExistNumber();
                              // if (isShowMissingEntriesSheet) {
                              //   // ignore: use_build_context_synchronously
                              //   // showMissingEntriesEnterSheet(context, user);
                              // }
                            });
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (showOverlay)
              Center(
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        width: width,
                        color: Colors.white,
                        child: const Padding(
                          padding: EdgeInsets.all(14.0),
                          child: Text(
                            signInSuccessMsg,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.green, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  //Asking Fill the phonenumber and email//
  // void showMissingEntriesEnterSheet(BuildContext context, User user) async {
  //   // ignore: use_build_context_synchronously
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     isDismissible: false,
  //     builder: (BuildContext context) {
  //       return WillPopScope(
  //         onWillPop: () async {return false;},
  //         child: Container(
  //           height: MediaQuery.of(context).size.height * 0.6,
  //           padding: const EdgeInsets.all(16.0),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               const Text(enterFieldsMsg,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: primaryColor)),
  //               const Divider(color: primaryColor),
  //               const SizedBox(height: 10),
  //               loginMethod == LoginMethod.google
  //               ? Column(
  //                   mainAxisAlignment: MainAxisAlignment.start,
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     const Text(enterNumberString,style:TextStyle(fontSize: 18, color: primaryColor)),
  //                     const SizedBox(height: 10),
  //                     TextFormField(
  //                       controller: phoneController,
  //                       keyboardType: TextInputType.phone,
  //                       onChanged: (value) {
  //                         setState(() {
  //                           updatePhoneNo = value;
  //                         });
  //                       },
  //                       decoration: const InputDecoration(
  //                         prefixIcon:Icon(Icons.phone, color: primaryColor),
  //                         hintText: phoneNoString,
  //                         hintStyle: TextStyle(color: primaryColor),
  //                         enabledBorder: OutlineInputBorder(
  //                           borderSide: BorderSide(color: Colors.black),
  //                           borderRadius:BorderRadius.all(Radius.circular(20))
  //                         ),
  //                         focusedBorder: OutlineInputBorder(
  //                           borderSide: BorderSide(color: Colors.black),
  //                           borderRadius:BorderRadius.all(Radius.circular(20))
  //                         )
  //                       ),
  //                     ),
  //                     const Align(
  //                       alignment: Alignment.bottomRight,
  //                       child: Text(exampleNoString,style: TextStyle(color: primaryColor))
  //                     )
  //                   ],
  //                 ): Container(),
  //               const SizedBox(height: 10),
  //               loginMethod == LoginMethod.phoneNumber
  //               ? Column(
  //                   mainAxisAlignment: MainAxisAlignment.start,
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     const Text(enterEmailString,style:TextStyle(fontSize: 18, color: primaryColor)),
  //                     const SizedBox(height: 10),
  //                     TextFormField(
  //                       controller: emailController,
  //                       keyboardType: TextInputType.text,
  //                       onChanged: (value) {
  //                         setState(() {
  //                           email = value;
  //                         });
  //                       },
  //                       decoration: const InputDecoration(
  //                         prefixIcon:Icon(Icons.mail, color: primaryColor),
  //                         hintText: emailAddString,
  //                         hintStyle: TextStyle(color: primaryColor),
  //                         enabledBorder: OutlineInputBorder(
  //                           borderSide: BorderSide(color: Colors.black),
  //                           borderRadius:BorderRadius.all(Radius.circular(20))
  //                         ),
  //                         focusedBorder: OutlineInputBorder(
  //                           borderSide: BorderSide(color: Colors.black),
  //                           borderRadius:BorderRadius.all(Radius.circular(20))
  //                         )
  //                       ),
  //                     ),
  //                   ],
  //                 ): Container(),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.end,
  //                 children: [
  //                   ElevatedButton(
  //                     onPressed: () async {
  //                       await authService.savePhoneNo(phoneController.text);
  //                       Get.back();
  //                       Get.snackbar(thankyouMsg,phoneNoUpdateSuccessMsg,colorText: primaryColor,snackPosition: SnackPosition.BOTTOM);
  //                       showProfileSheet(context);
  //                     },
  //                     style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
  //                     child: const Text(nextString)
  //                   ),
  //                   const SizedBox(width: 10),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}
