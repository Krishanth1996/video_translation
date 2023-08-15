import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_subtitle_translator/colors.dart';
import 'package:video_subtitle_translator/constants.dart';
import 'package:video_subtitle_translator/home.dart';
import 'package:video_subtitle_translator/services/firebase_services.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool passwordVisible = true;
  bool isLoading = false;
  bool isLoading1 = false;
  bool showOverlay = false;
  String phoneNumber = "";
  TextEditingController phoneNoController = TextEditingController();

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
                    SizedBox(
                      height: height / 3,
                    ),
                    Image.asset(
                      logoImg,
                      height: height / 1.25,
                    ),
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
                    const SizedBox(height: 16.0),
                    const SizedBox(height: 20.0),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: const RoundedRectangleBorder(borderRadius:BorderRadius.all(Radius.circular(20))),
                          padding: const EdgeInsets.all(15)),
                      onPressed:
                           () async {
                              setState(() {
                                isLoading1 = true;
                              });
                              
                              AuthService authService = AuthService();
                              await authService.initAuthService();

                              authService.verifyPhoneNumber(phoneNumber);
                              setState(() {
                                isLoading1 = false;
                              });
                            },
                      child: const Text(
                        loginString,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            googleImg,
                            height: 30,
                            width: 30,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          const Text(
                            signInGoogleString,
                            style: TextStyle(fontSize: 16),
                          )
                        ],
                      ),
                      onTap: () async {
                        setState(() {
                          isLoading = true; // Start loading
                        });

                        AuthService authService = AuthService();
                        await authService.initAuthService();

                        User? user = await AuthService().signInWithGoogle();
                        setState(() {
                          isLoading = false; // Stop loading
                          if (user != null) {
                            showOverlay = true; // Show the overlay
                            Future.delayed(const Duration(seconds: 2), () {
                              setState(() {
                                showOverlay = false;
                              });
                              Get.to(const Home());
                            });
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
             if (isLoading1) // Show the loading indicator conditionally
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (isLoading) // Show the loading indicator conditionally
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
}
