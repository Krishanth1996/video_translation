import 'package:flutter/material.dart';
import 'package:video_subtitle_translator/colors.dart';

class LoadingScreen extends StatelessWidget {
  final String text;
  final Color textColor;
  const LoadingScreen({
    super.key,
    required this.text,
    required this.textColor
   });

  @override
  Widget build(BuildContext context) {
    return  Align(
      alignment: Alignment.center,
      child: Center(
        child: Column(
          children:  [
            Text(text,style:  TextStyle(color: textColor),textAlign: TextAlign.center),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}