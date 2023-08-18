import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:video_subtitle_translator/constants.dart';
import 'package:video_subtitle_translator/services/firebase_services.dart';
import 'package:video_subtitle_translator/widgets/widgets.dart';
import 'package:video_subtitle_translator/widgets/loading_screen.dart';
import 'package:video_subtitle_translator/widgets/showSheet_screen.dart';
import 'colors.dart';
import 'package:video_subtitle_translator/widgets/remainingTimeWidget.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

final AuthService authService = AuthService();

class _HomeState extends State<Home> {
  String? displayName;
  String? email;
  String? uid;
  String? phoneNumber;
  String srtContent = '';
  String subtitles = '';
  String videoId = '';

  TextEditingController subtitleController = TextEditingController();

  VideoPlayerController? controller;
  final FlutterFFmpeg flutterFFmpeg = FlutterFFmpeg();

  late Future<void> initializeVideoPlayerFuture;
  late File videoFile;

  bool isVideoExist = false;
  bool isVideoPlaying = false;
  bool isLoadingVideo = false;
  bool showLoadingPopup = false;
  bool isEditingName = false;
  bool isAudioMuted = false;
  bool isTranscribing = false;
  bool canceledVideoLoading = false;
  bool isControlVisible = false;
  bool isVideoPlayerVisible = false;
  bool isVideoDeleting = false;
  bool isReachedLimit = false;

  List<String> extractedAudioPaths = [];
  List<Map<String, dynamic>> subtitleLines = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Duration videoDuration = Duration.zero;
  Duration currentPosition = Duration.zero;
  Timer? durationTimer;

  double durationInSeconds = 0;
  double remainingTime = 900;

  final CollectionReference usersCollection =FirebaseFirestore.instance.collection('Remaining_Time');

  @override
  void initState() {
    super.initState();
    controller?.addListener(_updateCurrentPosition);
    _startPositionListener();
    loadUserData();
    saveRemainingTime(0, email);
  }

  @override
  void dispose() {
    controller?.removeListener(_updateCurrentPosition);
    controller?.dispose();
    durationTimer?.cancel();
    super.dispose();
  }

  //Loading User Details//
  Future<void> loadUserData() async {
    authService.isUserLoggedIn();
    setState(() async {
      displayName = await authService.getDisplayName();
      email = await authService.getEmail();
      uid = await authService.getUid();
    });
  }

  Widget buildIndicator() {
    return VideoProgressIndicator(
      controller ?? VideoPlayerController.network(''),
      allowScrubbing: true,
      colors: const VideoProgressColors(
          playedColor: whiteColor, backgroundColor: borderColor),
    );
  }

  //Video timing while playing//
  void _updateCurrentPosition() {
    setState(() {
      currentPosition = controller?.value.position ?? Duration.zero;
    });
  }

  void _startPositionListener() {
    controller?.addListener(_updateCurrentPosition);
  }

  void onPositionChanged() {
    setState(() {
      currentPosition = controller?.value.position ?? Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  String generateVideoId() {
    // Generate a unique video ID using a timestamp and a random number
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    int randomNumber = Random().nextInt(999999);
    return '$timestamp$randomNumber';
  }

  //Get video from phone storage start//
  Future<void> getVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final videoPlayerController =
          VideoPlayerController.file(File(pickedFile.path));
      // Initialize the video player controller
      await videoPlayerController.initialize();
      await videoPlayerController.play();

      // Set the video duration
      setState(() {
        videoDuration = videoPlayerController.value.duration;
      });

      // Start the timer to update the running duration
      durationTimer = Timer.periodic(const Duration(milliseconds: 0), (_) {
        setState(() {
          currentPosition = videoPlayerController.value.position;
        });
      });

      // Check if the video duration is less than or equal to 60 seconds
      if (videoPlayerController.value.duration.inSeconds > 60) {
        setState(() {
          isLoadingVideo = false;
          showLoadingPopup = false;
        });
        // showLoadingPopup = false;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(select60MVideMsg), backgroundColor: primaryColor),
        );
        // Dispose the video player controller
        videoPlayerController.dispose();
        return;
      }

      // Dispose the video player controller
      videoPlayerController.dispose();
      setState(() {
        videoFile = File(pickedFile.path);
        print("print$videoFile");

        controller = VideoPlayerController.file(videoFile);
        initializeVideoPlayerFuture = controller!.initialize();

        controller!.setLooping(true);
        isVideoExist = true;
        isLoadingVideo = true;
        showLoadingPopup = true;
      });

      await Future.delayed(const Duration(seconds: 5));
      await initializeVideoPlayerFuture;
      setState(() {
        isLoadingVideo = false;
        showLoadingPopup = false;
      });
    }
  }
  //Get video from phone storage End//

  // Extract audio from imported video Start//
  Future<void> extractAudioFromVideo() async {
    Directory? appDir = await getExternalStorageDirectory();
    final String outputPath =
        '${appDir?.path}/audio${DateTime.now().millisecondsSinceEpoch}.m4a';
    String videoId = generateVideoId();
    var result = await flutterFFmpeg
        .execute('-i ${videoFile.path} -vn -c:a aac $outputPath');

    // Audio extraction successful
    if (result == 0) {
      setState(() {
        extractedAudioPaths.add(outputPath);
        showLoadingPopup = false;
        print('Successfully audio extract');
      });
      uploadAudioFileToStorage(outputPath, videoId);

      // Calculate audio duration
      File audioFile = File(outputPath);
      int fileSizeInBytes = await audioFile.length();
      double bitRate = 128000;
      durationInSeconds = fileSizeInBytes * 8 / bitRate;

      print("Extracted audio duration: $durationInSeconds seconds");
      showSubtitleSelectionSheet(context);
    } else {
      //Audio extraction failed
      Get.snackbar(sorryMsg, audioExtractFailMsg,
          snackPosition: SnackPosition.BOTTOM,
          titleText: const Text(sorryMsg, style: TextStyle(color: redColor)));
      setState(() {
        showLoadingPopup = false;
      });
    }
  }
  // Extract audio from imported video End//

  // Api call for convert text from extracted audio start //
  Future<void> convertAudioToText(String value) async {
    String apiUrl = 'https://transcribe.whisperapi.com';
    String apiKey = '9C6GBPCL1V8H3DWFSZHID64PUG6SSDZ2';
    String filePath = extractedAudioPaths.last;
    String fileType = 'm4a';

    var url = Uri.parse(apiUrl);
    var headers = {'Authorization': 'Bearer $apiKey'};
    var request = http.MultipartRequest('POST', url)
      ..headers.addAll(headers)
      ..fields.addAll({
        'fileType': fileType,
        'diarization': 'false',
        'numSpeakers': '2',
        'language': value,
        'task': 'transcribe',
      })
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    setState(() {
      isTranscribing = true;
    });
    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      print(responseBody);

      // Save the subtitle to Firestore
      saveSubtitleToFirestore(responseBody);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(subtitleCreateSuccessMsg,
              style: TextStyle(color: whiteColor)),
          backgroundColor: greenColor,
        ),
      );
    } else {
      print('Request failed with status: ${response.statusCode}');

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request failed with status: ${response.statusCode}'),
          backgroundColor: greenColor,
        ),
      );
    }
  }
  // Api call for convert text from extracted audio End//

  // Save converted subtitles in Firestore start //
  void saveSubtitleToFirestore(String subtitle) {
    CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('Subtitle_user');
    String uid = _auth.currentUser!.uid;
    String? email = _auth.currentUser!.email;

    usersCollection.doc(email).get().then((docSnapshot) {
      if (docSnapshot.exists) {
        usersCollection.doc(email).update({
          'transcriptions': FieldValue.arrayUnion([subtitle]),
          'timestamp': FieldValue.serverTimestamp(),
        }).then((_) {
          print('Subtitle updated for user: $uid');
        }).catchError((error) {
          print('Error updating user data: $error');
        });
      } else {
        usersCollection.doc(email).set({
          'timestamp': FieldValue.serverTimestamp(),
          'userId': uid,
          'videoId': DateTime.now().millisecondsSinceEpoch.toString(),
          'transcriptions': [
            subtitle
          ], // Store subtitles as an array of objects
        }).then((_) {
          print('New user document created: $uid');
        }).catchError((error) {
          print('Error creating user document: $error');
        });
      }

      setState(() {
        subtitleLines.clear(); // Clear the existing subtitle data

        var jsonResponse = json.decode(subtitle);
        var segments = jsonResponse['segments'];

        for (var segment in segments) {
          String text = segment['text'];
          double start = segment['start'];
          double end = segment['end'];

          subtitleLines.add({
            'text': text,
            'start': start,
            'end': end,
          });
        }

        subtitles = subtitleLines
            .map((line) => '${line['text']}  ${line['start']} - ${line['end']}')
            .join('\n\n');
        isTranscribing = false;
        subtitleController.text = subtitles;
      });
    }).catchError((error) {
      print('Error checking user document: $error');
    });
  }
  // Save converted subtitles in Firestore end //

  //Generate SRT File Start//
  String generateSRT(subtitleLines) {
    List<String> lines = subtitleLines.split('\n');
    StringBuffer srtContent = StringBuffer();
    for (int i = 0; i < lines.length; i++) {
      srtContent.writeln((i + 1).toString());
      // srtContent.writeln('00:00:00,000 --> 00:00:01,000');
      srtContent.writeln();
      srtContent.writeln(lines[i]);
    }
    return srtContent.toString();
  }
  //Generate SRT File End//

  //Save SRT File Start//
  void saveSRTToFile(String srtContent) {
    File file = File('subtitle.srt');
    file.writeAsStringSync(srtContent);
  }
  //Save SRT File End//

//Download SRT File Start//
  Future<void> downloadSRTFile() async {
    String srtContent = generateSRT(subtitles);
    String videoId = generateVideoId();

    Directory? appDocumentsDirectory = await getExternalStorageDirectory();
    String filePath = '${appDocumentsDirectory?.path}/subtitle.srt';

    File file = File(filePath);
    await file.writeAsString(srtContent);
    String downloadUrl = await uploadSRTFileToStorage(filePath, videoId);

    if (downloadUrl.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(srtFileCreateSuccessMsg),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(srtFileCreateFailMsg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> uploadSRTFileToStorage(String filePath, String videoId) async {
    try {
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('srt_files')
          .child(videoId)
          .child('subtitle.srt');

      final metadata = SettableMetadata(contentType: 'text/srt');
      UploadTask uploadTask =
          storageReference.putFile(File(filePath), metadata);
      TaskSnapshot taskSnapshot = await uploadTask;

      if (taskSnapshot.state == TaskState.success) {
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        return '';
      }
    } catch (error) {
      print('Error uploading SRT file: $error');
      return '';
    }
  }

  Future<String> uploadAudioFileToStorage(
      String filePath, String videoId) async {
    try {
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('audio_files')
          .child(videoId)
          .child('audio.m4a');

      final metadata = SettableMetadata(contentType: 'audio/m4a');
      UploadTask uploadTask =
          storageReference.putFile(File(filePath), metadata);
      TaskSnapshot taskSnapshot = await uploadTask;

      if (taskSnapshot.state == TaskState.success) {
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        return '';
      }
    } catch (error) {
      print('Error uploading SRT file: $error');
      return '';
    }
  }

  // Save user's remaining time and monthly limit to Firebase Firestore//
  void saveRemainingTime(double usedTimeInSeconds, String? email) {
    CollectionReference usersCollection =FirebaseFirestore.instance.collection('Remaining_Time');
    email = _auth.currentUser!.email;
    String uid = _auth.currentUser!.uid;

    DateTime now = DateTime.now();
    DateTime nextMonth =DateTime(now.year, now.month + 1, 1); // Start of the next month

    usersCollection.doc(email).get().then((docSnapshot) async {
      if (docSnapshot.exists) {
        Map<String, dynamic>? userData =docSnapshot.data() as Map<String, dynamic>?;
        if (userData != null) {
          double currentRemainingTime = userData['remainingTime'] as double;
          double currentMonthlyLimit = userData['monthlyLimit'] as double;

          if (now.isAfter(nextMonth)) {
            // Reset for a new month
            currentMonthlyLimit = 900.0; // Set the monthly limit to 900 seconds
            currentRemainingTime =900.0; // Reset remaining time to the new limit
          }

          double newRemainingTime = currentRemainingTime - usedTimeInSeconds;

          checkReachLimit(newRemainingTime, usedTimeInSeconds);
          if (newRemainingTime < 0) {
            newRemainingTime = 0;
            // usedTimeInSeconds = 900;
          }
          setState(() {
            remainingTime = newRemainingTime;
          });

          Map<String, dynamic> updateData = {
            'remainingTime': newRemainingTime,
            'timeStamp': FieldValue.serverTimestamp(),
            'monthlyLimit': currentMonthlyLimit, // Update the monthly limit
          };

          // Only update usedTime if newRemainingTime is not negative
          if (newRemainingTime > 0) {
            updateData['usedTime'] = FieldValue.increment(usedTimeInSeconds);
          }
          setState(() {
            remainingTime = newRemainingTime;
          });

          usersCollection.doc(email).update(updateData).then((_) {
            print('Remaining time updated for user: $email');
          }).catchError((error) {
            print('Error updating user data: $error');
          });
        }
      } else {
        // User's document doesn't exist, create a new document
        usersCollection.doc(email).set({
          'userId': uid,
          'timeStamp': FieldValue.serverTimestamp(),
          'remainingTime': 900.0 - usedTimeInSeconds, // Initial remaining time
          'monthlyLimit': 900.0, // Initial monthly limit
          'usedTime': usedTimeInSeconds,
        }).then((_) {
          print('New user document created: $email');
        }).catchError((error) {
          print('Error creating user document: $error');
        });
      }
    }).catchError((error) {
      print('Error checking user document: $error');
    });
  }

  double checkReachLimit(double newRemainingTime, double usedTimeInSeconds) {
    if (newRemainingTime < 0 ||
        usedTimeInSeconds >= 900 ||
        usedTimeInSeconds > newRemainingTime) {
      setState(() {
        isReachedLimit = true;
      });
      newRemainingTime = 0;
      remainingTime = newRemainingTime;
      // usedTimeInSeconds = 900; // Ensure it doesn't go negative
    }
    return newRemainingTime;
  }

  // Save user's remaining time and monthly limit to Firebase Firestore end//
  Future<bool> _onWillPop() async {
    return false;
  }

  void deleteVideo() {
    setState(() {
      isVideoExist = false;
      isVideoPlayerVisible = false;
      isControlVisible = false;
      isAudioMuted = false;
      isVideoDeleting = true;
      subtitles = '';
      if (isVideoPlaying == true) {
        controller?.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: primaryColor,
          automaticallyImplyLeading: false,
          title: const Text(appNameString),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.menu),
              offset: const Offset(0, 48),
              onSelected: (value) {
                if (value == 'Item 1') {} 
                else if (value == 'Item 2') {} 
                else if (value == 'Item 3') {}
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                //Profile Field//
                PopupMenuItem<String>(
                  padding: const EdgeInsets.only(left: 20, right: 50),
                  value: 'Item 1',
                  child: RowWIthIconTextbuttonWidget(
                    onPressed: () {
                      showProfileSheet(context);
                    },
                    icon: Icons.person,
                    text: profileString,
                  ),
                ),
                //Language Field//
                PopupMenuItem<String>(
                  padding: const EdgeInsets.only(left: 20, right: 50),
                  value: 'Item 2',
                  child: RowWIthIconTextbuttonWidget(
                    onPressed: () {},
                    icon: Icons.language,
                    text: languageString,
                  ),
                ),
                //Logout Field//
                PopupMenuItem<String>(
                  padding: const EdgeInsets.only(left: 20, right: 50),
                  value: 'Item 3',
                  child: RowWIthIconTextbuttonWidget(
                    onPressed: () async {
                      showLogoutAlertDialog(context);
                      if (isVideoPlaying) {
                        controller?.pause();
                      }
                    },
                    icon: Icons.logout,
                    text: logoutString,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Stack(children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  //Import Video Field Start//
                  if (!isVideoExist || isVideoExist)
                    RemainingTimeWidget(email?? ''),
                  if (!isVideoExist)
                    Container(
                      margin: EdgeInsets.only(top: width / 2),
                      child: ElevatedButtonCircularWidget(
                        onPressed: () async {
                          getVideo();
                          showLoadingPopup = true;
                        },
                        backgroundColor:primaryColor,
                        child:const RowWithIconTextWidget(text: importVideoString,icon: Icons.video_collection,iconColor: whiteColor,textColor: whiteColor,fontSize: 20,),
                      ),
                    ),
                  const SizedBox(height: 16.0),
                  //Video Container Field Start//
                  if (isVideoExist)
                    Container(
                      width: width,
                      padding: const EdgeInsets.all(10),
                      decoration: boxDecoration1,
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 300,
                              height: 250,
                              margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
                              decoration: boxDecoration2,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      AspectRatio(
                                        aspectRatio:controller!.value.aspectRatio,
                                        child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                isControlVisible =!isControlVisible;
                                              });
                                            },
                                            child: VideoPlayer(controller!)),
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:MainAxisAlignment.spaceEvenly,
                                    children: [
                                      VideoPlayingIconsWidget(
                                        visible: isControlVisible,
                                        icon: Icons.fast_rewind,
                                        onPressed: (){controller?.seekTo(Duration(seconds: controller!.value.position.inSeconds -5));},
                                      ),
                                      VideoPlayingIconsWidget(
                                        visible: isControlVisible,
                                        icon: isVideoPlaying? Icons.pause: Icons.play_arrow,
                                        onPressed: () {
                                          setState(() {
                                            if (isVideoPlaying) {
                                              controller?.pause();
                                            } else {
                                              controller?.play();
                                            }
                                            isVideoPlaying = !isVideoPlaying;
                                          });
                                        },
                                      ),
                                      VideoPlayingIconsWidget(
                                        visible: isControlVisible,
                                        icon: Icons.fast_forward,
                                        onPressed: (){controller?.seekTo(Duration(seconds: controller!.value.position.inSeconds +5));},
                                      ),
                                    ],
                                  ),
                                  VideoDurationShowWidget(
                                    text:"${_formatDuration(controller!.value.position)} / ${_formatDuration(videoDuration)}",
                                  ),
                                  VideoAudioIconWidget(
                                    isAudioMuted: isAudioMuted,
                                    onPressed: () {
                                      setState(() {
                                        if (isAudioMuted) {controller?.setVolume(1.0);} 
                                        else {controller?.setVolume(0.0);}
                                        isAudioMuted = !isAudioMuted;
                                      });
                                    },
                                  ),
                                  Positioned(bottom: 10,left: 20,right: 20,child: buildIndicator()),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButtonCircularWidget(
                            onPressed: () async {
                              // saveRemainingTime(durationInSeconds, email);
                              if (remainingTime <= videoDuration.inSeconds) {
                                showLimitAlert(context);
                              } else {
                                extractAudioFromVideo();
                              }
                            },
                            backgroundColor: primaryColor,
                            child: const RowWithIconTextWidget(text:createSubtitleString,icon:Icons.closed_caption,iconColor: whiteColor,textColor: whiteColor,fontSize: 20,),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            children: [
                              if (isTranscribing)const Center(child: LoadingScreen())
                              else if (subtitles.isNotEmpty)
                                Container(
                                  height: 200,
                                  margin: const EdgeInsets.all(10),
                                  decoration: boxDecoration,
                                  padding: const EdgeInsets.all(15),
                                  child: ListView.builder(
                                    itemCount: subtitleLines.length,
                                    itemBuilder: (context, index) {
                                      String text =subtitleLines[index]['text'];
                                      double start =subtitleLines[index]['start'] * 1000;
                                      double end =subtitleLines[index]['end'] * 1000;

                                      Duration currentPosition =controller!.value.position;
                                      bool isHighlighted = currentPosition.inMilliseconds >=start &&currentPosition.inMilliseconds <= end;

                                      return Row(
                                        mainAxisAlignment: isHighlighted
                                            ? MainAxisAlignment.center
                                            : MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              text,
                                              style: TextStyle(
                                                fontSize:isHighlighted ? 17 : 14,
                                                color: isHighlighted? Colors.green: blackColor,
                                                fontWeight: isHighlighted? FontWeight.bold: FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 20),
                              Container(
                                margin: const EdgeInsets.only(left: 10),
                                child: Row(
                                  mainAxisAlignment:MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButtonCircularWidget(
                                      onPressed: () {
                                        showAlertDialog();
                                      }, 
                                      backgroundColor: whiteColor, 
                                      child: const RowWithIconTextWidget(
                                        text: discardString,textColor: primaryColor,fontSize: 15,
                                        icon: Icons.delete,iconColor: primaryColor,
                                      )
                                    ),
                                    subtitles.isNotEmpty? 
                                    ElevatedButtonCircularWidget(
                                      onPressed: (){downloadSRTFile();}, 
                                      backgroundColor: primaryColor, 
                                      child: const RowWithIconTextWidget(text: downloadSRTString,icon: Icons.download)
                                    ): Container()
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showLoadingPopup)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: SizedBox(
                  width: 400,
                  height: 300,
                  child: AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const <Widget>[
                        Text(loadingMsg, textAlign: TextAlign.center),
                        SizedBox(height: 20),
                        CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  void showSubtitleSelectionSheet(
    BuildContext context,
  ) {
    // Home homeScreen = Get.put(Home());
    String selectedLanguage = 'en';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      builder: (BuildContext context) {
        double width = MediaQuery.of(context).size.width;
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RowWithTextIconButtonWidget(text: generateSubtitleMsg,),
              const Divider(color: borderColor),
              const SizedBox(height: 20),
              const Text(selectTranslateLanguageMsg,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedLanguage,
                onChanged: (newValue) {
                  selectedLanguage = newValue!;
                },
                decoration: InputDecoration(
                    filled: true,
                    hintText: selectLanguageMsg,
                    hintStyle: TextStyle(fontSize: width / 5 * 0.2),
                    prefixIcon: const Icon(Icons.language, color: primaryColor),
                    contentPadding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(color: primaryColor, width: 2)),
                    errorBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: redColor, width: 2),
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(color: redColor, width: 2),
                    )),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'en',
                    child: Text('English'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'fr',
                    child: Text('French'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'de',
                    child: Text('German'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'es',
                    child: Text('Spanish'),
                  ),
                ],
              ),
              const Divider(color: borderColor),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButtonWidget(
                    onPressed: () async {
                      Get.back(); // Close the bottom sheet
                      await convertAudioToText(selectedLanguage);
                      saveRemainingTime(durationInSeconds, email);
                    },
                    backgroundColor: primaryColor,
                    child: const Text(generateSubtitleString),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButtonWidget(
                    onPressed: () async {
                      Get.back();
                    },
                    backgroundColor: borderColor,
                    child: const Text(closeString),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.bottomCenter,
                child: Text(translationMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: primaryColor)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> showAlertDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                confirmString,
                style: TextStyle(color: primaryColor, fontSize: 20),
              ),
              Divider(color: borderColor),
              Text(
                confirmRemoveMsg,
                style: TextStyle(color: primaryColor, fontSize: 16),
              )
            ],
          ),
          actions: <Widget>[
            ElevatedButtonWidget(
              onPressed: (){
                Get.back();
              }, 
              backgroundColor: borderColor,
              child: const Text(cancelString,style: TextStyle(color: whiteColor, fontSize: 15))
            ),
            ElevatedButtonWidget(
              onPressed: (){
                deleteVideo();
                Get.back();
              }, 
              backgroundColor: primaryColor,
              child: const Text(yesString,style: TextStyle(color: whiteColor, fontSize: 15))
            ),
          ],
        );
      },
    );
  }
}










