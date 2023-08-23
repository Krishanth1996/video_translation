// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:youtube_explode_dart/youtube_explode_dart.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// import 'package:http/http.dart' as http;

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

//   Future<void> downloadVideo() async {
//     Dio dio = Dio();

//     try {
//       var dir = await getApplicationDocumentsDirectory();
//       print("path ${dir.path}");
//       await dio.download(videoUrl, "${dir.path}/demo.mp4",
//           onReceiveProgress: (rec, total) {
//         print("Rec: $rec , Total: $total");
//         print('dir.path');

//         setState(() {
//           downloading = true;
//           progressString = ((rec / total) * 100).toStringAsFixed(0) + "%";
//         });
//       });
//     } catch (e) {
//       print(e);
//     }

//     setState(() {
//       downloading = false;
//       progressString = "Completed";
//     });
//     print("Download completed");
//   }


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
//       backgroundColor: const Color.fromARGB(255, 226, 224, 218),
//       appBar: AppBar(
//         title: const Text('Video Translator'),
//         centerTitle: true,
//         backgroundColor: Colors.black,
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
//                   hintText: 'Import Your Video URL',
//                   hintStyle: TextStyle(color: Colors.black,),
//                   enabledBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Colors.black),
//                     borderRadius: BorderRadius.all(Radius.circular(20)),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Colors.black),
//                     borderRadius: BorderRadius.all(Radius.circular(20)),
//                   ),
//                   prefixIcon: Icon(FontAwesomeIcons.arrowUpFromBracket,color: Colors.black,)
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
//                   backgroundColor: Colors.black,
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
//                   downloadVideo(); 
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
//                     Icon(FontAwesomeIcons.closedCaptioning),
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


// final DatabaseReference _videoRef = FirebaseDatabase.instance.reference().child('videos');

//   void saveVideoDetails(String videoUrl, List<Map<String, dynamic>> subtitles) {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final newVideoRef = _videoRef.child(user.uid).push();
//       newVideoRef.set({
//         'videoUrl': videoUrl,
//         'subtitles': subtitles,
//         'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
//         // Add other video details here
//       }).then((_) {
//         print('Video details saved successfully.');
//       }).catchError((error) {
//         print('Error saving video details: $error');
//       });
//     }
//   }


// void showProfileSheet(BuildContext context) async {
//   AuthService authService = AuthService();
//   LoginMethod loginMethod = LoginMethod.phoneNumber;
//   // LoginMethod loginMethodGoogle = LoginMethod.google;
//   await authService.initAuthService();
//   String displayName = await authService.getDisplayName();
//   String email = await authService.getEmail();
//   String uid = await authService.getUid();
//   // String phone = await authService.getUpdatePhoneNo();
//   String phoneNo = await authService.getPhoneNo();
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   bool isGoogleLogin = false;
  
//   checkLoginMethod() {
//     if (loginMethod == LoginMethod.google) {
//       isGoogleLogin = true;
//       return isGoogleLogin;
//     } 
//     else {
//       isGoogleLogin = false;
//       return isGoogleLogin;
//     }
//   }

//   // String existingPhoneNumber = '';
//   // ignore: use_build_context_synchronously
//   showTopModalSheet(
//       context,
//       Container(
//         height: MediaQuery.of(context).size.height * 0.4,
//         width: MediaQuery.of(context).size.width * 0.9,
//         padding: const EdgeInsets.all(16.0),
//         child: Container(
//           margin: const EdgeInsets.only(top: 20),
//           child: Column(
//             children: [
//               checkLoginMethod()== true?
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(userProfileString,
//                             style: TextStyle(
//                                 fontSize: 22,
//                                 fontWeight: FontWeight.bold,
//                                 color: primaryColor)),
//                         IconButton(
//                             onPressed: () {
//                               Get.back();
//                             },
//                             icon: const Icon(Icons.close))
//                       ],
//                     ),
//                   const Divider(color: borderColor),
//                   const Text(emailString,
//                       style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: primaryColor)),
//                   const SizedBox(height: 5),
//                   Text(email, style: const TextStyle(fontSize: 15)),
//                   const SizedBox(height: 10),
//                   const Text(nameString,
//                       style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: primaryColor)),
//                   const SizedBox(height: 5),
//                   Text(displayName, style: const TextStyle(fontSize: 15)),
//                   // const SizedBox(height: 10),
//                   // Row(
//                   //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   //   children: [
//                   //     Column(
//                   //       mainAxisAlignment: MainAxisAlignment.start,
//                   //       crossAxisAlignment: CrossAxisAlignment.start,
//                   //       children: [
//                   //         const Text(phoneString,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: primaryColor)),
//                   //         const SizedBox(height: 5),
//                   //         Text(existingPhoneNumber.isNotEmpty ? existingPhoneNumber : phone, style: const TextStyle(fontSize: 15)),
//                   //       ],
//                   //     ),
//                   //   ],
//                   // ),
                  
//                   const SizedBox(height: 10),
//                   Align(
//                       alignment: Alignment.center,
//                       child: ElevatedButton(
//                           onPressed: () {},
//                           style: ElevatedButton.styleFrom(
//                               backgroundColor: primaryColor),
//                           child: const Text(deleteAccString))),
//                 ],
//               ):Container(),
//               if(loginMethod == LoginMethod.phoneNumber) 
//                     Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(userProfileString,
//                             style: TextStyle(
//                                 fontSize: 22,
//                                 fontWeight: FontWeight.bold,
//                                 color: primaryColor)),
//                         IconButton(
//                             onPressed: () {
//                               Get.back();
//                             },
//                             icon: const Icon(Icons.close))
//                       ],
//                     ),
//                   const Divider(color: borderColor),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Column(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const Text(phoneString,
//                                     style: TextStyle(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold,
//                                         color: primaryColor)),
//                                 const SizedBox(height: 5),
//                                 Text(phoneNo, style: const TextStyle(fontSize: 15)),
//                                 // const SizedBox(height: 10),
//                                 // const Text(emailString,style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: primaryColor)),
//                                 // const SizedBox(height: 5),
//                                 // Text(email, style: const TextStyle(fontSize: 15)),
//                                 // const SizedBox(height: 10)
//                               ],
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 10),
//                   Align(
//                       alignment: Alignment.center,
//                       child: ElevatedButton(
//                           onPressed: () {},
//                           style: ElevatedButton.styleFrom(
//                               backgroundColor: primaryColor),
//                           child: const Text(deleteAccString))),
//                       ],
//                     )
//             ],
//           ),
//         ),
//       ),
//       barrierDismissible: false);
// }