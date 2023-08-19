// import 'package:flutter/material.dart';
// import 'package:video_subtitle_translator/colors.dart';
// import 'package:youtube_explode_dart/youtube_explode_dart.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   TextEditingController urlController=TextEditingController();
//   String videoUrl='';
//   bool isVideoExist=false;
//   bool isVideoPlaying = false;

//   bool downloading = false;
//   var progressString = "";
//   YoutubePlayerController? controller;

//   void disposeController() {
//     controller?.dispose();
//   }

//   void setVideoController() {
//     disposeController();
//     controller = YoutubePlayerController(
//       initialVideoId: YoutubePlayer.convertUrlToId(videoUrl) ?? '',
//       flags: const YoutubePlayerFlags(autoPlay: false),
//     ); 
//   }
// Future<void> getVideo() async {
//     final videoUrl = urlController.text.trim();
    
//     if (videoUrl.isNotEmpty) {
//       try {
//         final ytExplode = YoutubeExplode();
//         final videoId = YoutubePlayer.convertUrlToId(videoUrl);

//         if (videoId != null) {
//           final video = await ytExplode.videos.get(videoId);

//           setState(() {
//             controller = YoutubePlayerController(
//               initialVideoId: videoId,
//               flags: const YoutubePlayerFlags(
//                 autoPlay: false,
//               ),
//             );
//             isVideoExist = true;
//           });
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Invalid YouTube URL'),backgroundColor: Color.fromARGB(255, 202, 81, 127),),
//           );
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('An error occurred: $e'),backgroundColor:  const Color.fromARGB(255, 202, 81, 127),),
//         );
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter a valid YouTube URL'),backgroundColor: Color.fromARGB(255, 202, 81, 127),),
//       );
//     }
//   }

//   // Future<void> downloadVideo() async {
//   //   // Dio dio = Dio();

//   //   try {
//   //     var dir = await getApplicationDocumentsDirectory();
//   //     print("path ${dir.path}");
//   //     await dio.download(videoUrl, "${dir.path}/demo.mp4",
//   //         onReceiveProgress: (rec, total) {
//   //       print("Rec: $rec , Total: $total");
//   //       print('dir.path');

//   //       setState(() {
//   //         downloading = true;
//   //         progressString = ((rec / total) * 100).toStringAsFixed(0) + "%";
//   //       });
//   //     });
//   //   } catch (e) {
//   //     print(e);
//   //   }

//   //   setState(() {
//   //     downloading = false;
//   //     progressString = "Completed";
//   //   });
//   //   print("Download completed");
//   // }


// //   Future<void> downloadVideo() async {
// //   final videoUrl = urlController.text.trim();

// //   if (videoUrl.isNotEmpty) {
// //     try {
// //       final response = await http.get(Uri.parse(videoUrl));
// //       if (response.statusCode == 200) {
// //         final appDocumentsDir = await getExternalStorageDirectory();
// //         final videoFile = File('${appDocumentsDir!.path}/video.mp4');
// //         await videoFile.writeAsBytes(response.bodyBytes);
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text('Video downloaded successfully!'),
// //             backgroundColor: Colors.green,
// //           ),
// //         );
// //       } 
// //       else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text('Failed to download video.'),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     } 
// //     catch (e) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text('An error occurred: $e'),
// //           backgroundColor: Colors.red,
// //         ),
// //       );
// //     }
// //   } 
// //   else {
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(
// //         content: Text('Please enter a valid video URL'),
// //         backgroundColor: Color.fromARGB(255, 202, 81, 127),
// //       ),
// //     );
// //   }
// // }

// // Future<void> downloadVideo(String videoUrl) async {
// //   try {
// //     final response = await http.get(Uri.parse(videoUrl));
// //     if (response.statusCode == 200) {
// //       final appLocalDir = await getApplicationDocumentsDirectory();
// //       // final appDocumentsDir = await getExternalStorageDirectory();
// //       //final file = File('${appDocumentsDir!.path}/video.mp4');
// //       final file = File('${appLocalDir.path}/video.mp4');
// //       await file.writeAsBytes(response.bodyBytes);

// //       print('Video downloaded successfully!');
// //       print('File path: ${file.path}');
// //     } else {
// //       print('Failed to download video. Status code: ${response.statusCode}');
// //     }
// //   } catch (e) {
// //     print('An error occurred while downloading the video: $e');
// //   }
// // }

//   @override
//   Widget build(BuildContext context) {
//    return Scaffold(
//       appBar: AppBar(
//         title: const Text('Video Translator'),
//         centerTitle: true,
//         backgroundColor: primaryColor,
//         automaticallyImplyLeading: false,
//         actions: [
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.menu,),
//             offset: const Offset(0, 48), 
//             onSelected: (value) {
//               if (value == 'Item 1') {
//               } 
//               else if (value == 'Item 2') {
//               }
//               else if (value == 'Item 3') {
//               }
//             },
//             itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//                PopupMenuItem<String>(
//                 padding: const EdgeInsets.only(left: 20,right: 50),
//                 value: 'Item 1',
//                 child: Row(
//                   children: const [
//                     Icon(Icons.person,color: Colors.black,),
//                     SizedBox(width: 10,),
//                     Text('My Profile'),
//                   ],
//                 ),
//               ),
//               PopupMenuItem<String>(
//                 padding: const EdgeInsets.only(left: 20,right: 50),
//                 value: 'Item 2',
//                 child: Row(
//                   children: const [
//                     Icon(Icons.language,color: Colors.black,),
//                     SizedBox(width: 10,),
//                     Text('Language'),
//                   ],
//                 ),
//               ),
//               PopupMenuItem<String>(
//                 padding: const EdgeInsets.only(left: 20,right: 50),
//                 value: 'Item 3',
//                 child: Row(
//                   children: const[
//                     Icon(Icons.logout,color: Colors.black,),
//                     SizedBox(width: 10,),
//                     Text('Logout'),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               TextField(
//                 controller:urlController ,
//                 onChanged: (value) {
//                   setState(() {
//                     videoUrl = value;
//                     isVideoExist = false;
//                   });
//                 },
//                 decoration:  const InputDecoration(
//                   hintText: 'Enter Your Video URL here',
//                   hintStyle: TextStyle(color: Colors.black,),
//                   enabledBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Colors.black),
//                     borderRadius: BorderRadius.all(Radius.circular(20)),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Colors.black),
//                     borderRadius: BorderRadius.all(Radius.circular(20)),
//                   ),
//                   prefixIcon: Icon(Icons.link,color: Colors.black,)
//                 ),
//               ),
//               const SizedBox(height: 16.0),
//               Container(
//                 width: 300,
//                 height: 220,
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.black),
//                   borderRadius: const BorderRadius.all(Radius.circular(20))
//                 ),
//                  child: isVideoExist
//                     ? YoutubePlayer(
//                         controller: controller!,
//                         showVideoProgressIndicator: true,
//                         progressIndicatorColor: Colors.blue,
//                         progressColors: const ProgressBarColors(
//                           playedColor: Colors.red,
//                           handleColor: Colors.black,
//                         ),
//                       )
//                     : Container(),
//               ),
//               const SizedBox(height: 16.0),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                    IconButton(
//                     icon: const Icon(Icons.fast_rewind),
//                     onPressed: () {
//                       controller?.seekTo(Duration(seconds: controller!.value.position.inSeconds - 10));
//                     },
//                   ),
//                   IconButton(
//                     icon: Icon(
//                       isVideoPlaying? Icons.pause : Icons.play_arrow,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         if(isVideoPlaying){
//                           controller?.pause();
//                         }
//                         else{
//                           controller?.play();
//                         }
//                         isVideoPlaying=!isVideoPlaying;
//                       });
//                     },
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.fast_forward),
//                     onPressed: () {
//                       controller?.seekTo(Duration(seconds: controller!.value.position.inSeconds + 10));
//                     },
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16.0),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryColor,
//                   shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
//                   padding: const EdgeInsets.all(15)
//                 ),
//                 onPressed: () {
//                   getVideo();
//                   setVideoController();
//                 },
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: const [
//                     Icon(Icons.videocam_sharp),
//                     SizedBox(width: 5,),
//                     Text(
//                       'Get Video',
//                       style: TextStyle(color: Colors.white,fontSize: 15),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10,),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.black,
//                   shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
//                   padding: const EdgeInsets.all(15)
//                 ),
//                 onPressed: () {
//                   // downloadVideo(urlController.text); 
//                   // downloadVideo(); 
//                 },
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: const [
//                     Icon(Icons.download),
//                     SizedBox(width: 5,),
//                     Text(
//                       'Download Video',
//                       style: TextStyle(color: Colors.white,fontSize: 15),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10,),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.black,
//                   shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
//                   padding: const EdgeInsets.all(15)
//                 ),
//                 onPressed: () {
                 
//                 },
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: const [
//                     // Icon(FontAwesomeIcons.closedCaptioning),
//                     SizedBox(width: 10),
//                     Text(
//                       'Create Subtitle ',
//                       style: TextStyle(color: Colors.white,fontSize: 15),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }