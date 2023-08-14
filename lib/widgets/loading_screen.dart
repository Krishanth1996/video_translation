import 'package:flutter/material.dart';
import 'package:video_subtitle_translator/colors.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    super.key,
   });

  @override
  Widget build(BuildContext context) {
    return  Align(
      alignment: Alignment.center,
      child: Column(
        children: const [
          Text('Please Wait'),
          CircularProgressIndicator(
            color: primaryColor,
          ),
        ],
      ),
    );
  }
}