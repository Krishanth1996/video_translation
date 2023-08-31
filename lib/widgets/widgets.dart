import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_subtitle_translator/colors.dart';

class ElevatedButtonCircularWidget extends StatelessWidget {
  final void Function()? onPressed;
  final Widget? child;
  final Color backgroundColor;
  const ElevatedButtonCircularWidget(
      {super.key,
      required this.onPressed,
      required this.child,
      required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                side: BorderSide(color: primaryColor)),
            padding: const EdgeInsets.all(15)),
        onPressed: onPressed,
        child: child);
  }
}

class ElevatedButtonWidget extends StatelessWidget {
  const ElevatedButtonWidget(
      {super.key,
      required this.onPressed,
      required this.backgroundColor,
      required this.child});
  final void Function()? onPressed;
  final Color backgroundColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: backgroundColor),
      child: child,
    );
  }
}

class VideoPlayingIconsWidget extends StatelessWidget {
  const VideoPlayingIconsWidget(
      {super.key,
      required this.onPressed,
      required this.visible,
      required this.icon});

  final void Function()? onPressed;
  final bool visible;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: IconButton(
        icon: Icon(
          icon,
          color: whiteColor,
          size: 40,
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class VideoDurationShowWidget extends StatelessWidget {
  const VideoDurationShowWidget({super.key, required this.text,required this.visible});

  final String text;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 15),
        child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 13))),
      ),
    );
  }
}

class VideoAudioIconWidget extends StatelessWidget {
  const VideoAudioIconWidget(
      {super.key, required this.isAudioMuted, required this.onPressed,required this.visible});

  final bool isAudioMuted;
  final void Function()? onPressed;
  final bool visible;


  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 15),
        child: Align(
          alignment: Alignment.bottomRight,
          child: IconButton(
            icon: Icon(isAudioMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

class RowWIthIconTextbuttonWidget extends StatelessWidget {
  final void Function()? onPressed;
  final String text;
  final IconData icon;
  const RowWIthIconTextbuttonWidget(
      {super.key, required this.onPressed, required this.text,required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: primaryColor),
        const SizedBox(width: 10),
        TextButton(
            onPressed: onPressed,
            child: Text(text, style: const TextStyle(color: primaryColor))),
      ],
    );
  }
}

class RowWithIconTextWidget extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? iconColor;
  final Color? textColor;
  final double? fontSize;
  final double? iconSize;
  const RowWithIconTextWidget(
      {super.key,
      required this.text,
      required this.icon,
      this.iconColor,
      this.textColor,
      this.fontSize,
      this.iconSize
    });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor,size: iconSize,),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: textColor, fontSize: fontSize)),
      ],
    );
  }
}

class RowWithTextIconButtonWidget extends StatelessWidget {
  const RowWithTextIconButtonWidget({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor)),
        IconButton(
            onPressed: () {
              Get.back();
            },
            icon: const Icon(Icons.close, color: primaryColor))
      ],
    );
  }
}
