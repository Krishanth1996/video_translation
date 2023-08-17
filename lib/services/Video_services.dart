// import 'dart:async';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:video_player/video_player.dart';

// class VideoInfo {
//   late Duration videoDuration;
//   late Duration currentPosition;
//   late Timer durationTimer;
//   late bool isLoadingVideo;
//   late bool isVideoExist;
//   late bool showLoadingPopup;
//   late VideoPlayerController videoPlayerController;
//   // late XFile? pickedFile;
//   late File videoFile;
//   late VideoPlayerController? controller;
//   late Future<void> initializeVideoPlayerFuture;
// }

// class VideoServices {
//   //Get video from phone storage start//
//   static Future<VideoInfo?> getVideo() async {
//     final VideoInfo info = VideoInfo();
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       info.videoPlayerController =
//           VideoPlayerController.file(File(pickedFile.path));
//       // Initialize the video player controller
//       // await videoPlayerController.initialize();
//       // await videoPlayerController.play();

//       // Set the video duration
//       info.videoDuration =info. videoPlayerController.value.duration;

//       // Start the timer to update the running duration
//       info.durationTimer = Timer.periodic(const Duration(milliseconds: 0), (_) {
//         info.currentPosition = info.videoPlayerController.value.position;
//       });

//       // Check if the video duration is less than or equal to 60 seconds
//       // if (info.videoPlayerController.value.duration.inSeconds > 60) {
//       //   info.isLoadingVideo = false;
//       //   info.showLoadingPopup = false;
//       //   // showLoadingPopup = false;
//       //   // ignore: use_build_context_synchronously
//       //   // ScaffoldMessenger.of(context).showSnackBar(
//       //   //   const SnackBar(
//       //   //       content: Text(select60MVideMsg), backgroundColor: primaryColor),
//       //   // );
//       //   // Dispose the video player controller
//       //   info.videoPlayerController.dispose();
//       //   return null;
//       // }

//       // Dispose the video player controller
//       // info.videoPlayerController.dispose();

//       info.videoFile = File(pickedFile.path);
//       print("print ${info.videoFile}");

//       info.controller = VideoPlayerController.file(info.videoFile);
//       // info.initializeVideoPlayerFuture = info.controller!.initialize();

//       info.controller!.setLooping(true);
//       info.isVideoExist = true;
//       info.isLoadingVideo = true;
//       info.showLoadingPopup = true;

//       // await Future.delayed(const Duration(seconds: 5));
//       // await info.initializeVideoPlayerFuture;

//       // info.isLoadingVideo = false;
//       // info.showLoadingPopup = false;

//       return info;
//     }
//   }
//   //Get video from phone storage End//
// }
// // Future<void> getVideo() async {
//   //   var info = await VideoServices.getVideo();

//   //   setState(() {
//   //     controller = info!.controller;
//   //     currentPosition = info.currentPosition;
//   //     durationTimer = info.durationTimer;
//   //     initializeVideoPlayerFuture = info.controller!.initialize();
//   //     // initializeVideoPlayerFuture = info.initializeVideoPlayerFuture;
//   //     isLoadingVideo = info.isLoadingVideo;
//   //     isVideoExist = info.isVideoExist;
//   //     showLoadingPopup = info.showLoadingPopup;
//   //     videoDuration = info.videoDuration;
//   //     videoFile = info.videoFile;
//   //     info.videoPlayerController;
//   //   });
//   //     await info!.videoPlayerController.initialize();
//   //     await info.videoPlayerController.play();

//   //     if (info.videoPlayerController.value.duration.inSeconds > 60) {
//   //       info.isLoadingVideo = false;
//   //       info.showLoadingPopup = false;
//   //       // showLoadingPopup = false;
//   //       // ignore: use_build_context_synchronously
//   //       // ScaffoldMessenger.of(context).showSnackBar(
//   //       //   const SnackBar(
//   //       //       content: Text(select60MVideMsg), backgroundColor: primaryColor),
//   //       // );
//   //       // Dispose the video player controller
//   //       info.videoPlayerController.dispose();
//   //       return null;
//   //     }
//   //     info.videoPlayerController.dispose();


//   //   // ignore: use_build_context_synchronously
//   //   ScaffoldMessenger.of(context).showSnackBar(
//   //     const SnackBar(
//   //         content: Text(select60MVideMsg), backgroundColor: primaryColor),
//   //   );
//   //   // Dispose the video player controller

//   //   setState(() {
//   //     isLoadingVideo = info!.isLoadingVideo;
//   //     showLoadingPopup = info.showLoadingPopup;
//   //   });

//   //   await Future.delayed(const Duration(seconds: 5));
//   //   await initializeVideoPlayerFuture;

//   //   setState(() {
//   //     isLoadingVideo = false;
//   //     showLoadingPopup = false;
//   //   });
//   // }