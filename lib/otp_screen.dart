import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:video_subtitle_translator/home.dart';
import 'package:video_subtitle_translator/services/firebase_services.dart';
import 'colors.dart';
import 'constants.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNo;

  const OTPVerificationScreen(this.phoneNo, this.verificationId, {super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  TextEditingController otpController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  String otpNumber = "";
  bool isLoading = false;
  bool showOverlay = false;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        centerTitle: true,
        title: const Text("OTP Verification"),
      ),
      body: Stack(children: [
        Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "OTP Verification",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                'We have sent the code verification to\n ${widget.phoneNo}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 60),
              Pinput(
                length: 6,
                controller: otpController,
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    isLoading = true;
                  });
                  authService.submitOTP(otpController.text.trim());
                  setState(() {
                    isLoading = false;
                    showOverlay = true;
                    Future.delayed(const Duration(seconds: 10), () {
                      setState(() {
                        showOverlay = false;
                      });
                      //  Get.to(const Home());
                     });
                  });
                  print(otpController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  padding: const EdgeInsets.all(15),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(fontSize: 18),
                ),
              )
            ],
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
      ]),
    );
  }
}
