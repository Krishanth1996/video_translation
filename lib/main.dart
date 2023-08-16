import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_subtitle_translator/firebase_options.dart';
import 'package:video_subtitle_translator/home.dart';
import 'package:video_subtitle_translator/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if(authService.isUserLoggedIn()){
      return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
    } else{
      return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Login(),
    );
    }
  }
}
