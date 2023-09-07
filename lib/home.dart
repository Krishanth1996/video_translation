import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' ;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:video_subtitle_translator/constants.dart';
import 'package:video_subtitle_translator/services/firebase_services.dart';
import 'package:video_subtitle_translator/widgets/subtitle_colors.dart';
import 'package:video_subtitle_translator/widgets/widgets.dart';
import 'package:video_subtitle_translator/widgets/loading_screen.dart';
import 'package:video_subtitle_translator/widgets/showSheet_screen.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'colors.dart';
import 'package:video_subtitle_translator/widgets/remainingTimeWidget.dart';
import 'package:cloud_functions/cloud_functions.dart';

class VideoInfo {
  final File videoFile;
  final String subtitle;

  VideoInfo(this.videoFile, this.subtitle);
}

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
  String? videoName;
  String editedSubtitle = '';
  String videoUrl = '';
  String downloadUrl='';
  String fileName = '';
  String? selectedFontStyle;
  String? photo='';

  User? user;

  TextEditingController subtitleController = TextEditingController();
  TextEditingController urlController = TextEditingController();

  YoutubePlayerController? youtubeController;
  VideoPlayerController? controller;

  final FlutterFFmpeg flutterFFmpeg = FlutterFFmpeg();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference usersCollection =FirebaseFirestore.instance.collection('Remaining_Time');

  late Future<void> initializeVideoPlayerFuture;
  late File videoFile;
  File? selectedVideoFile;

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
  bool isLocalStorageVideo = false;
  bool isGoogleLogin = false;
  bool isEditing = false;
  bool isSelectStyle= false;
  bool isDownloadingVideo =false;
  bool isDownloadingSrt =false;
  bool isGettingKey=false;

  List<String> extractedAudioPaths = [];
  List<String> downloadedVideoPaths = [];
  List<Map<String, dynamic>> subtitleLines = [];
  
  double durationInSeconds = 0;
  double remainingTime = 900;
  double start=0;
  double end=0;
  int currentSubtitleIndex = 0;

  Duration videoDuration = Duration.zero;
  Duration currentPosition = Duration.zero;
  Timer? durationTimer;

  Color userSelectedBgColor=Colors.black.withOpacity(0.2);
  Color userSelectedTextColor=whiteColor;


  @override
  void initState() {
    super.initState();
    controller?.addListener(_updateCurrentPosition);
    _startPositionListener();
    loadUserData();
    saveRemainingTime(0, uid);
    updateSubtitleIndex(currentPosition);
  }

  @override
  void dispose() {
    controller?.removeListener(_updateCurrentPosition);
    controller?.dispose();
    durationTimer?.cancel();
    super.dispose();
  }
  
  //Loading user details//
  Future<void> loadUserData() async {
    authService.isUserLoggedIn();
    setState(() async {
      displayName = await authService.getDisplayName();
      email = await authService.getEmail();
      uid = await authService.getUid();
      phoneNumber = await authService.getPhoneNo();
      photo=await authService.getPhoto();
    });
  }
  //Loading user details end//

  //Video playing indicator field//
  Widget buildIndicator() {
    return VideoProgressIndicator(
      controller ?? VideoPlayerController.network(''),
      allowScrubbing: true,
      colors: const VideoProgressColors(
          playedColor: whiteColor, backgroundColor: borderColor),
    );
  }
  //Video playing indicator field end//
  
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
  //Video timing while playing end//

  //Time duration calculation of video//
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
  //Time duration calculation of video end//

  //Generate video id//
  String generateVideoId() {
    // Generate a unique video ID using a timestamp and a random number
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    int randomNumber = Random().nextInt(999999);
    return '$timestamp$randomNumber';
  }
  //Generate video id end//

  //Get video from phone storage//
  Future<void> getVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
   
    if (pickedFile != null) {
      final videoPlayerController =VideoPlayerController.file(File(pickedFile.path));
      videoName = pickedFile.name;
      videoFile = File(pickedFile.path);
      videoUrl=pickedFile.path;

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

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(select60MVideMsg), backgroundColor: primaryColor),
        );
        // Dispose the video player controller
        videoPlayerController.dispose();
        return;
      }

      // Dispose the video player controller
      videoPlayerController.dispose();
      setState(() {
        videoFile = File(pickedFile.path);
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
    else{
      setState(() {
        isLoadingVideo = false;
        showLoadingPopup=false;
      });
    }
  }
  //Get video from phone storage End//

  // Extract audio from imported phone storage video//
  Future<void> extractAudioFromVideo() async {
    Directory? appDir = await getExternalStorageDirectory();
    final String outputPath ='${appDir?.path}/audio${DateTime.now().millisecondsSinceEpoch}.m4a';
    String videoId = generateVideoId();
    var result = await flutterFFmpeg.execute('-i ${videoFile.path} -vn -c:a aac $outputPath');
    // Audio extraction successful//
    if (result == 0) {
      setState(() {
        extractedAudioPaths.add(outputPath);
        showLoadingPopup = false;
      });

      //Upload extracted audio to firebase storage//
      uploadAudioFileToStorage(outputPath, videoId);

      // Calculate audio duration
      File audioFile = File(outputPath);
      int fileSizeInBytes = await audioFile.length();
      double bitRate = 128000;
      durationInSeconds = fileSizeInBytes * 8 / bitRate;
      
      // ignore: use_build_context_synchronously
      showSubtitleSelectionSheet(context);
    } 
    // Audio extraction fail//
    else if (result == 1) {
      Get.snackbar(sorryMsg, notAbleCreateSubtitleMsg,backgroundColor: redColor.withOpacity(0.2),snackPosition: SnackPosition.BOTTOM,titleText: const Text(sorryMsg, style: TextStyle(color: redColor)));
      setState(() {
        showLoadingPopup = false;
      });
    } 
  }
  // Extract audio from imported video End//

  //Get api key and api url from database through cloud function//
  Future<Map<String, dynamic>?> getApiInfoFromCloudFunction() async {
    final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getApiInfo');
    setState(() {
      isGettingKey=true;
    });
    try {
      final response = await callable.call();
      final responseData = Map<String, dynamic>.from(response.data);
      setState(() {
        isGettingKey=false;
      });
      return responseData;
    } on FirebaseFunctionsException catch (e) {
      return null;
    }
  }
  //Get api key and api url from database through cloud function end//

  // Api call for convert text from extracted audio//
  Future<void> convertAudioToText(String value) async {
    final apiInfo = await getApiInfoFromCloudFunction();

    if (apiInfo == null) {
      return;
    }

    String apiUrl = apiInfo['apiUrl'];
    String apiKey = apiInfo['apiKey'];

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

      // Save the subtitle to Firestore
      saveSubtitleToFirestore(responseBody);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(subtitleCreateSuccessMsg,style: TextStyle(color: whiteColor)),
          backgroundColor: greenColor,
        ),
      );
    } else {
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

  // Save converted subtitles in Firestore//
  void saveSubtitleToFirestore(String subtitle) {
    CollectionReference usersCollection =FirebaseFirestore.instance.collection('Subtitle_user');
    String uid = _auth.currentUser!.uid;

    usersCollection.doc(uid).get().then((docSnapshot) {
      if (docSnapshot.exists) {
        usersCollection.doc(uid).update({
          'transcriptions': FieldValue.arrayUnion([subtitle]),
          'timestamp': FieldValue.serverTimestamp(),
        }).then((_) {}).catchError((error) {});
      } else {
        usersCollection.doc(uid).set({
          'timestamp': FieldValue.serverTimestamp(),
          'userId': uid,
          'videoId': DateTime.now().millisecondsSinceEpoch.toString(),
          'transcriptions': [
            subtitle
          ], // Store subtitles as an array of objects
        }).then((_) {}).catchError((error) {});
      }

      setState(() {
        subtitleLines.clear(); // Clear the existing subtitle data

        //Get subtitles line by line according to time interval//
        var jsonResponse = json.decode(subtitle);
        var segments = jsonResponse['segments'];

        for (var segment in segments) {
          String text = segment['text'];
          start = segment['start'];
          end = segment['end'];

          subtitleLines.add({
            'text': text,
            'start': start,
            'end': end,
          });
        }

        subtitles = subtitleLines.map((line) => '${line['text']}  ${line['start']} - ${line['end']}').join('\n\n');
        isTranscribing = false;
        subtitleController.text = subtitles;
      });
    }).catchError((error) {});
  }
  // Save converted subtitles in Firestore end //

  //Get subtitle for current position//
  String getSubtitleForCurrentPosition(Duration currentPosition) {
    for (var subtitleLine in subtitleLines) {
      double start = subtitleLine['start'] * 1000;
      double end = subtitleLine['end'] * 1000;

      if (currentPosition.inMilliseconds >= start &&
          currentPosition.inMilliseconds <= end) {
        return subtitleLine['text'];
      }
    }
    return ''; 
  }
  //Get subtitle for current position end //

  // Format time to srt file generation//
  String formatTime(double seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds ~/ 60) % 60;
    int remainingSeconds = (seconds % 60).toInt();
    int milliseconds = ((seconds - seconds.floor()) * 1000).toInt();

    return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')},${milliseconds.toString().padLeft(3, '0')}';
  }
  // Format time to srt file generation end//

  //Generate SRT file start//
  String generateSRT(List<Map<String, dynamic>> subtitleLines) {
    StringBuffer srtContent = StringBuffer();
    
    for (int i = 0; i < subtitleLines.length; i++) {
      double startInSeconds = subtitleLines[i]['start'];
      double endInSeconds = subtitleLines[i]['end'];
      String text = subtitleLines[i]['text'];
        
      // Convert start and end times to hh:mm:ss,mmm format
      String startTime = formatTime(startInSeconds);
      String endTime = formatTime(endInSeconds);

      // Create formatted HTML-like subtitle text
      srtContent.writeln('${i + 1}');
      srtContent.writeln('$startTime --> $endTime');
      srtContent.writeln(text);
      srtContent.writeln();
    }
    
    return srtContent.toString();
  }
  //Generate SRT File End//

  //Download SRT file//
  Future<void> downloadSRTFile() async {
    String srtContent = generateSRT((subtitleLines));
    String videoId = generateVideoId();
    setState(() {
       isDownloadingSrt=true;
     });
    Directory? appDocumentsDirectory = await getExternalStorageDirectory();
    String filePath = '${appDocumentsDirectory?.path}/subtitles.srt';

    File file = File(filePath);
    await file.writeAsString(srtContent);
    String downloadUrl = await uploadSRTFileToStorage(filePath, videoId);

    if (downloadUrl.isNotEmpty) {
       await Future.delayed(const Duration(seconds: 3));
      setState(() {
        isDownloadingSrt = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(srtFileCreateSuccessMsg),
          backgroundColor: greenColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(srtFileCreateFailMsg),
          backgroundColor: redColor,
        ),
      );
    }
  }
  //Download SRT file end//

  //Upload SRT file to firebase storage//
  Future<String> uploadSRTFileToStorage(String filePath, String videoId) async {
    try {
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('srt_files')
          .child(videoId)
          .child('subtitle.srt');

      final metadata = SettableMetadata(contentType: 'text/srt');
      UploadTask uploadTask =storageReference.putFile(File(filePath), metadata);
      TaskSnapshot taskSnapshot = await uploadTask;

      if (taskSnapshot.state == TaskState.success) {
        downloadUrl = await taskSnapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        return '';
      }
    } catch (error) {
      return '';
    }
  }
  //Upload SRT file to firebase storage end//

  //Upload audio file to firebase storage//
  Future<String> uploadAudioFileToStorage(String filePath, String videoId) async {
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
      return '';
    }
  }
  //Upload audio file to firebase storage end//

  // Save user's remaining time and monthly limit to Firebase Firestore//
  void saveRemainingTime(double usedTimeInSeconds, String? uid) {
    CollectionReference usersCollection =FirebaseFirestore.instance.collection('Remaining_Time');
    email = _auth.currentUser!.email;
    String uid = _auth.currentUser!.uid;

    DateTime now = DateTime.now();
    DateTime nextMonth =DateTime(now.year, now.month + 1, 1); // Start of the next month

    usersCollection.doc(uid).get().then((docSnapshot) async {
      if (docSnapshot.exists) {
        Map<String, dynamic>? userData =
            docSnapshot.data() as Map<String, dynamic>?;
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

          usersCollection.doc(uid).update(updateData).then((_) {}).catchError((error) {});
        }
      } else {
        // User's document doesn't exist, create a new document
        usersCollection.doc(uid).set({
          'userId': uid,
          'timeStamp': FieldValue.serverTimestamp(),
          'remainingTime': 900.0 - usedTimeInSeconds, // Initial remaining time
          'monthlyLimit': 900.0, // Initial monthly limit
          'usedTime': usedTimeInSeconds,
        }).then((_) {}).catchError((error) {});
      }
    }).catchError((error) {});
  }
  // Save user's remaining time and monthly limit to Firebase Firestore end//

  //Check time reach limit for user//
  double checkReachLimit(double newRemainingTime, double usedTimeInSeconds) {
    if (newRemainingTime < 0 ||usedTimeInSeconds >= 900 ||usedTimeInSeconds > newRemainingTime) {
      setState(() {
        isReachedLimit = true;
      });
      newRemainingTime = 0;
      remainingTime = newRemainingTime;
      // usedTimeInSeconds = 900; // Ensure it doesn't go negative
    }
    return newRemainingTime;
  }
  //Check time reach limit for user end//

  //Avoid getback after login once//
  Future<bool> _onWillPop() async {
    return false;
  }
  //Avoid getback after login once end//

  //Delete video when click discard//
  void deleteVideo() {
    setState(() {
      isVideoExist = false;
      isVideoPlayerVisible = false;
      isControlVisible = false;
      isAudioMuted = false;
      isVideoDeleting = true;
      if (isVideoPlaying == true) {
        controller?.pause();
      }
      if (isVideoPlaying == true) {
        youtubeController?.pause();
      }
      urlController.clear();
      subtitleLines = [];
      subtitles = '';
    });
  }
  //Delete video when click discard end//

  //Get youtube video by url//
  Future<void> getYoutubeVideo() async {
    final videoUrl = urlController.text.trim();

    if (videoUrl.isNotEmpty) {
      try {
        final ytExplode = YoutubeExplode();
        final videoId = YoutubePlayer.convertUrlToId(videoUrl);

        if (videoId != null) {
          final video = await ytExplode.videos.get(videoId);
          if(video.duration!.inSeconds<=60){
            setState(() {
              youtubeController = YoutubePlayerController(
                initialVideoId: videoId,
                flags: const YoutubePlayerFlags(
                  autoPlay: false,
                ),
              );
              isVideoExist = true;
              videoDuration = video.duration!;
            });
            late Timer positionTimer;
          positionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() {
              currentPosition = youtubeController!.value.position;
            });
            });
          }
          else{
            urlController!.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(select60MVideMsg), backgroundColor: primaryColor),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(invalidUrlMsg,style: TextStyle(color: whiteColor)),
              backgroundColor: redColor,
            ),
          );
          urlController.clear();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e',style: const TextStyle(color: whiteColor),),
            backgroundColor: redColor,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(enterUrlMsg),
            backgroundColor: primaryColor),
      );
    }
  }
  //Get youtube video by url end//

  //Dispose youtube controller//
  void disposeController() {
    youtubeController?.dispose();
  }
  //Dispose youtube controller end//

  //Set youtube video controller//
  void setVideoController() {
    disposeController();
    youtubeController = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId(videoUrl) ?? '',
      flags: const YoutubePlayerFlags(autoPlay: false),
    );
  }
  //Set youtube video controller end//

  //Download youtube video//
  Future<void> downloadYoutubeVideo() async {
    final videoUrl = urlController.text.trim();
    if (videoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(videoUrl));
        if (response.statusCode == 200) {
          final appDocumentsDir = await getExternalStorageDirectory();

          String outputPath ='${appDocumentsDir?.path}/video$videoId.mp4';

          final videoFile = File('${appDocumentsDir?.path}/video.mp4');
          await videoFile.writeAsBytes(response.bodyBytes);

          setState(() {
            downloadedVideoPaths.add(outputPath);
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(enterUrlMsg),
          backgroundColor: primaryColor,
        ),
      );
    }
  }
  //Download youtube video end//

  //fetch youtube video infomation//
  Future<void> fetchVideoInfoAndExtractAudio(String videoUrl) async {
    final youtube = YoutubeExplode();

    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    var manifest = await youtube.videos.streamsClient.getManifest(videoId);
    var streams = manifest.audioOnly;

    // Get the audio track with the highest bitrate.
    var audio = streams.first;

    // Get the audio stream URL
    Uri audioStreamUrl = audio.url;

    youtube.close();

    // Call the function to start audio extraction
    await extractAudioFromUrl(audioStreamUrl.toString());
  }
  //fetch youtube video infomation end//

  //Extract audio of youtube video//
  Future<void> extractAudioFromUrl(String audioStreamUrl) async {
    final flutterFFmpeg = FlutterFFmpeg();
    String videoFilePath = downloadedVideoPaths.last;
    String directoryPath = videoFilePath.replaceAll(RegExp(r'/[^/]*$'), '');
    final outputPath ='$directoryPath/audio${DateTime.now().millisecondsSinceEpoch}.m4a';
    setState(() {
      extractedAudioPaths.add(outputPath);
    });
    final arguments = [
      '-i', audioStreamUrl,
      '-vn', // Disable video
      '-c:a', 'aac', // Use the AAC codec
      outputPath,
    ];
    // saveRemainingTime()
    final result = await flutterFFmpeg.executeWithArguments(arguments);
    uploadAudioFileToStorage(outputPath, videoId);
    // Calculate audio duration
    File audioFile = File(outputPath);
    int fileSizeInBytes = await audioFile.length();
    double bitRate = 128000;
    durationInSeconds = fileSizeInBytes * 8 / bitRate;
    showSubtitleSelectionSheet(context);
  }
  //Extract audio of youtube video end//

  //Retrieve subtitle from database//
  Future<List<Map<String, dynamic>>> retrieveSubtitlesFromFirestore() async {
    CollectionReference subtitlesCollection = FirebaseFirestore.instance.collection('Subtitle_user');
    String uid = _auth.currentUser!.uid;

    DocumentSnapshot userDoc = await subtitlesCollection.doc(uid).get();
    if (userDoc.exists) {
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      if (userData != null) {
        List<dynamic>? subtitlesData = userData['transcriptions'];

        if (subtitlesData != null) {
          List<Map<String, dynamic>> subtitles = [];
          for (var subtitle in subtitlesData) {
            var jsonResponse = json.decode(subtitle);
            var segments = jsonResponse['segments'];

            for (var segment in segments) {
              String text = segment['text'];
              double start = segment['start'];
              double end = segment['end'];

              subtitles.add({
                'text': text,
                'start': start,
                'end': end,
              });
            }
          }

          return subtitles;
        } else {
          return []; // No subtitles found for the user
        }
      } else {
        return []; // No subtitles found for the user
      }
    } else {
      return []; // No subtitles found for the user
    }
  }
  //Retrieve subtitle from database end//

  //Update subtitles after edit//
  void updateSubtitleIndex(currentPosition) {
    setState(() {
      for (int i = 0; i < subtitleLines.length; i++) {
        double start = subtitleLines[i]['start'] * 1000;
        double end = subtitleLines[i]['end'] * 1000;

        if (currentPosition.inMilliseconds >= start && currentPosition.inMilliseconds <= end) {
          currentSubtitleIndex = i;
          break;
        }
      }
    });
  }
  //Update subtitles after edit end//

  //Download video with subtitles embedded//
  Future<void> downloadVideoWithSubtitles(BuildContext context) async {
    final appDocumentsDir = await getExternalStorageDirectory();

    final String downloadPath = '${appDocumentsDir?.path}/video${DateTime.now().millisecondsSinceEpoch}.mkv'; // Adjust the path
    String videoFilePath='';
    
    if(isLocalStorageVideo) {
     setState(() {
       isDownloadingVideo=true;
     });
      videoFilePath =videoUrl;
    
    // Generate and save SRT subtitles
    final String subtitles = generateSRT(subtitleLines);
    final String subtitleFilePath = '${appDocumentsDir?.path}/subtitles.srt';
    await File(subtitleFilePath).writeAsString(subtitles);
    final flutterFFmpeg = FlutterFFmpeg();
    final int result = await flutterFFmpeg.execute('-i $videoFilePath -i $subtitleFilePath $downloadPath');
     String videoId = generateVideoId();
    // // Append subtitles to the downloaded video
    if (result == 0) {
      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        isDownloadingVideo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(videoDownloadMsg), backgroundColor: greenColor),);
      uploadVideoToStorage(downloadPath,videoId);
    } 
    else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(videoDownloadFailMsg), backgroundColor: redColor),);
    }
    }

    else{
      setState(() {
       isDownloadingVideo=true;
     });
      final youtube = YoutubeExplode();
      final videoId = YoutubePlayer.convertUrlToId(videoUrl);
      var manifest = await youtube.videos.streamsClient.getManifest(videoId);
      var streamsAudio=manifest.audioOnly;
      var audio=streamsAudio.first;
      Uri audioStreamUrl = audio.url;

      var streams= manifest.videoOnly;
      var video = streams.first;
      Uri videoStreamUrl = video.url;

      final appDocumentsDir = await getExternalStorageDirectory();
      videoFilePath='${appDocumentsDir?.path}/video$videoId.mp4';

      // Generate and save SRT subtitles
    final String subtitles = generateSRT(subtitleLines);
    final String subtitleFilePath = '${appDocumentsDir?.path}/subtitles.srt';
    await File(subtitleFilePath).writeAsString(subtitles);
    final flutterFFmpeg = FlutterFFmpeg();
    final int result = await flutterFFmpeg.execute('-i $videoStreamUrl -i $audioStreamUrl -i $subtitleFilePath -c:a copy -c:v copy $downloadPath');
    // // Append subtitles to the downloaded video
    if (result == 0) {
      String downloadUrl = await uploadVideoToStorage(downloadPath, videoId!);
      if(downloadUrl.isNotEmpty){
        setState(() {
          isDownloadingVideo=false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(videoDownloadMsg), backgroundColor: greenColor),);
      }
    } 
    else {
      // setState(() {
      //   isDownloading=false;
      // });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(videoDownloadFailMsg), backgroundColor: primaryColor),);
    }
    }
  }
  //Download video with subtitles embedded end//

  //Upload SRT file to firebase storage//
Future<String> uploadVideoToStorage(String filePath, String videoId) async {
  try {
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('video_files')
        .child(videoId)
        .child('video.mkv');

    final metadata = SettableMetadata(contentType: 'video/mkv');
    UploadTask uploadTask = storageReference.putFile(File(filePath), metadata);
    TaskSnapshot taskSnapshot = await uploadTask;

    if (taskSnapshot.state == TaskState.success) {
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } else {
      return ''; // Return an appropriate error message if needed
    }
  } catch (error) {
    print('Error uploading video: $error');
    return ''; // Return an appropriate error message if needed
  }
}
  // //Upload SRT file to firebase storage end//
 

  //Get color HexCode//
  String getColorHexCode(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0')}';
  }
  //Get color HexCode end//

  //Get available font styles//
  List<String> getAvailableFontStyles() {
    return GoogleFonts.asMap().keys.toList();
  }
  //Get available font styles end//

  // Save subtitle's textcolor and backgroundcolor//
  void saveColorsToFirestore(Color txtcolor, Color bgcolor) {
    CollectionReference usersCollection =FirebaseFirestore.instance.collection('colors_Subtitle');
    String uid = _auth.currentUser!.uid;

    String txtColorHex = '#${txtcolor.value.toRadixString(16).substring(2)}';
    String bgColorHex = '#${bgcolor.value.toRadixString(16).substring(2)}';

    usersCollection.doc(uid).get().then((docSnapshot) {
      if (docSnapshot.exists) {
        usersCollection.doc(email).update({
          'textColor': txtColorHex,
          'bgColor': bgColorHex,
          'timeStamp': FieldValue.serverTimestamp(),
          'fontStyle':selectedFontStyle,
        }).then((_) {}).catchError((error) {});
      } else {
        usersCollection.doc(uid).set({
          'timeStamp': FieldValue.serverTimestamp(),
          'userId': uid,
          'textColor': txtColorHex,
          'bgColor': bgColorHex,
          'fontStyle':selectedFontStyle,
        }).then((_) {}).catchError((error) {});
      }
    }).catchError((error) {});
  }
  // Save subtitle's textcolor and backgroundcolor end//
  
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
                //Profile field//
                PopupMenuItem<String>(
                  padding: const EdgeInsets.only(left: 20, right: 50),
                  value: 'Item 1',
                  child: Row(
                    children: [
                      // Icon(icon, color: primaryColor),
                      CircleAvatar(
                          radius:10, // Adjust the size of the circle as needed
                          backgroundImage: NetworkImage(photo ?? ''),
                        ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () {
                          showProfileSheet(context);
                        },
                        child: const Text(profileString, style: TextStyle(color: primaryColor))),
                    ],
                  ),
                ),
                //Logout field//
                PopupMenuItem<String>(
                  padding: const EdgeInsets.only(left: 20, right: 50),
                  value: 'Item 2',
                  child: RowWIthIconTextbuttonWidget(
                    onPressed: () async {
                      showLogoutAlertDialog(context);
                      if (isVideoPlaying) {
                        controller?.pause();
                        youtubeController!.pause();
                      }
                    },
                    icon: Icons.logout,
                    text: logoutString,
                  ),
                ),
                //Logout field end//
                //Delete account field//
                PopupMenuItem<String>(
                  padding: const EdgeInsets.only(left: 20, right: 50),
                  value: 'Item 3',
                  child: RowWIthIconTextbuttonWidget(
                    onPressed: () {
                      if (isVideoPlaying) {
                        controller?.pause();
                        youtubeController!.pause();
                      }
                      showDeleteAccount(context);
                    },
                    icon: Icons.delete,
                    text: deleteAccString,
                  ),
                ),
                //Delete account field end//
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
              
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child:Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  //Remaining time bar widget//
                  if (!isVideoExist || isVideoExist) RemainingTimeWidget(_auth.currentUser?.uid),
                  //If video is not existing show this field//
                  if (!isVideoExist)
                    Container(
                      margin: EdgeInsets.only(top: width / 2.2),
                      child: Column(
                        children: [
                          //Import local storage video field//
                          ElevatedButtonCircularWidget(
                            onPressed: () async {
                              isLocalStorageVideo = true;
                              getVideo();
                              setState(() {
                                isVideoPlaying=false;
                                showLoadingPopup=false;
                              });
                            },
                            backgroundColor: primaryColor,
                            child: const RowWithIconTextWidget(
                              text: importVideoString,textColor: whiteColor,fontSize: 20,
                              icon: Icons.video_collection,iconSize: 20,iconColor: whiteColor,
                            ),
                          ),
                          //Import local storage video field end//
                          const SizedBox(height: 20),
                          //Import youtube video URL field//
                          ElevatedButtonCircularWidget(
                            onPressed: () {
                              showImportUrlSheet(context);
                            },
                            backgroundColor: primaryColor,
                            child: const RowWithIconTextWidget(
                              textColor: whiteColor,text: importUrlString,fontSize: 20,
                              icon: CupertinoIcons.link,iconSize: 20,iconColor: whiteColor,
                            ),
                          ),
                          //Import youtube video URL field end//
                        ],
                      ),
                    ),
                  const SizedBox(height: 16.0),
                  //If video existing show video container field//
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
                                  //If video is local storage video//
                                  if (isLocalStorageVideo)
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      //Video container//
                                      AspectRatio(
                                        aspectRatio: controller!.value.aspectRatio,
                                        child: Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  isControlVisible = !isControlVisible;
                                                });
                                              },
                                              child: VideoPlayer(controller!),
                                            ),
                                            //If subtitle is not editing show subtitles in video//
                                            if (!isEditing && subtitles.isNotEmpty)
                                            Positioned(
                                              bottom: 10,
                                              left: 10,
                                              right: 10,
                                              child: Container(
                                                color: userSelectedBgColor,
                                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                                child: Text(
                                                  getSubtitleForCurrentPosition(controller!.value.position),
                                                  style: isSelectStyle?
                                                    GoogleFonts.getFont(
                                                          selectedFontStyle! ,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: userSelectedTextColor,
                                                        ):  TextStyle(fontSize: 14,color: userSelectedTextColor)
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        offset: const Offset(0, 26),
                                        onSelected: (value) {
                                          if (value == 'Item 1') {} 
                                          else if (value == 'Item 2') {} 
                                          else if (value == 'Item 3') {}
                                        },
                                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                          //Change subtitle text color//
                                          PopupMenuItem<String>(
                                            padding: const EdgeInsets.only(left: 20,right: 8),
                                            value: 'Item 1',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.abc, color: primaryColor),
                                                const SizedBox(width: 10),
                                                TextButton(
                                                    onPressed: () async {
                                                      await showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return TextColorPickerDialog(
                                                          pickerColor: userSelectedTextColor,
                                                          onColorChanged: (colortxt) {
                                                            print("Selected color: $colortxt");
                                                            setState(() {
                                                              userSelectedTextColor=colortxt ;
                                                            });
                                                          },
                                                        );
                                                      },
                                                    );
                                                    if (userSelectedTextColor != null) {
                                                      saveColorsToFirestore(userSelectedTextColor,userSelectedBgColor);
                                                    }
                                                  },
                                                  child: const Text('Edit Text Color',
                                                  style: TextStyle(color: primaryColor))),
                                              ],
                                            ),
                                          ),
                                          //Change subtitle background color//
                                          PopupMenuItem<String>(
                                            padding: const EdgeInsets.only(left: 20,right: 8),
                                            value: 'Item 2',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.color_lens, color: primaryColor),
                                                const SizedBox(width: 10),
                                                TextButton(
                                                    onPressed: () async{
                                                  await showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return BackgroundColorPickerDialog(
                                                      pickerColor: userSelectedBgColor,
                                                      onColorChanged: (colorbg) {
                                                        print("Selected color: $colorbg");
                                                        setState(() {
                                                          userSelectedBgColor = colorbg;
                                                        });
                                                      },
                                                    );
                                                  },
                                                );
                                                  if(userSelectedBgColor !=null) {
                                                  saveColorsToFirestore(userSelectedTextColor,userSelectedBgColor);
                                                  }
                                                    },
                                                  child: const Text('Edit Bg Color',
                                                  style: TextStyle(color: primaryColor)))
                                              ],
                                            ),
                                          ),
                                          // Change subtitle font style //
                                        PopupMenuItem<String>(
                                          padding: const EdgeInsets.only(left: 20,right: 8),
                                          value: 'Item 3',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.font_download_outlined, color: primaryColor),
                                              const SizedBox(width: 10),
                                              TextButton(
                                                onPressed: () async {
                                                  List<String> fontStyles = getAvailableFontStyles();
                                                  await showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        title: const Text('Available Font Styles'),
                                                        content: Container(
                                                          width: double.maxFinite,
                                                          child: ListView.builder(
                                                            itemCount: fontStyles.length,
                                                            itemBuilder: (context, index) {
                                                              return ListTile(
                                                                title: Text(fontStyles[index]),
                                                                onTap: () {
                                                                  setState(() {
                                                                    isSelectStyle=true;
                                                                    selectedFontStyle = fontStyles[index];
                                                                    saveColorsToFirestore(userSelectedTextColor,userSelectedBgColor);
                                                                  });
                                                                  Navigator.pop(context);
                                                                  Navigator.pop(context);
                                                                },
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                                child: const Text('Edit Font Style', style: TextStyle(color: primaryColor)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ],
                                      ), 
                                      ),
                                      ],
                                    )
                                  //If video is youtube url video//
                                  else
                                    Stack(
                                    alignment: Alignment.center,
                                      children: [
                                        Container(
                                        width: 300,
                                        height: 250,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.black),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(20)),
                                        ),
                                        child: youtubeController != null
                                            ? Stack(
                                              fit:StackFit.expand,
                                              children:[ YoutubePlayer(
                                                controller: youtubeController!,
                                                showVideoProgressIndicator: true,
                                                progressIndicatorColor:Colors.blue,
                                                progressColors:const ProgressBarColors(
                                                  playedColor: Colors.red,
                                                  handleColor: Colors.black,
                                                ),
                                                onReady: () {
                                                  // You can disable controls here
                                                  youtubeController!.setPlaybackRate(1); // Set normal playback rate
                                                },
                                              ),
                                              Positioned.fill(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    // Implement play/pause logic here
                                                    if (youtubeController!.value.isPlaying) {
                                                      youtubeController!.pause();
                                                    } else {
                                                      youtubeController!.play();
                                                    }
                                                  },
                                                ),
                                              ),
                                      ])
                                            : const Center(child:CircularProgressIndicator(),),
                                      ),
                                      if (!isEditing && subtitles.isNotEmpty)
                                            Positioned(
                                              bottom: 10,
                                              left: 10,
                                              right: 10,
                                              child: Container(
                                                color: userSelectedBgColor,
                                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                                child: Text(
                                                  getSubtitleForCurrentPosition(youtubeController!.value.position),
                                                  style: isSelectStyle?
                                                    GoogleFonts.getFont(
                                                          selectedFontStyle! ,
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: userSelectedTextColor,
                                                        ):  TextStyle(fontSize: 14,color: userSelectedTextColor)
                                                ),
                                              ),
                                            ),
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert,color: whiteColor,),
                                        offset: const Offset(0, 26),
                                        onSelected: (value) {
                                          if (value == 'Item 1') {} 
                                          else if (value == 'Item 2') {} 
                                          else if (value == 'Item 3') {}
                                        },
                                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                          //Change subtitle text color//
                                          PopupMenuItem<String>(
                                            padding: const EdgeInsets.only(left: 20,right: 8),
                                            value: 'Item 1',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.abc, color: primaryColor),
                                                const SizedBox(width: 10),
                                                TextButton(
                                                    onPressed: () async {
                                                      await showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return TextColorPickerDialog(
                                                          pickerColor: userSelectedTextColor,
                                                          onColorChanged: (colortxt) {
                                                            print("Selected color: $colortxt");
                                                            setState(() {
                                                              userSelectedTextColor=colortxt ;
                                                            });
                                                          },
                                                        );
                                                      },
                                                    );
                                                    if (userSelectedTextColor != null) {
                                                      saveColorsToFirestore(userSelectedTextColor,userSelectedBgColor);
                                                    }
                                                  },
                                                  child: const Text('Edit Text Color',
                                                  style: TextStyle(color: primaryColor))),
                                              ],
                                            ),
                                          ),
                                          //Change subtitle background color//
                                          PopupMenuItem<String>(
                                            padding: const EdgeInsets.only(left: 20,right: 8),
                                            value: 'Item 2',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.color_lens, color: primaryColor),
                                                const SizedBox(width: 10),
                                                TextButton(
                                                    onPressed: () async{
                                                  await showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return BackgroundColorPickerDialog(
                                                      pickerColor: userSelectedBgColor,
                                                      onColorChanged: (colorbg) {
                                                        print("Selected color: $colorbg");
                                                        setState(() {
                                                          userSelectedBgColor = colorbg;
                                                        });
                                                      },
                                                    );
                                                  },
                                                );
                                                  if(userSelectedBgColor !=null) {
                                                  saveColorsToFirestore(userSelectedTextColor,userSelectedBgColor);
                                                  }
                                                    },
                                                  child: const Text('Edit Bg Color',
                                                  style: TextStyle(color: primaryColor)))
                                              ],
                                            ),
                                          ),
                                          // Change subtitle font style //
                                        PopupMenuItem<String>(
                                          padding: const EdgeInsets.only(left: 20,right: 8),
                                          value: 'Item 3',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.font_download_outlined, color: primaryColor),
                                              const SizedBox(width: 10),
                                              TextButton(
                                                onPressed: () async {
                                                  List<String> fontStyles = getAvailableFontStyles();
                                                  await showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        title: const Text('Available Font Styles'),
                                                        content: Container(
                                                          width: double.maxFinite,
                                                          child: ListView.builder(
                                                            itemCount: fontStyles.length,
                                                            itemBuilder: (context, index) {
                                                              return ListTile(
                                                                title: Text(fontStyles[index]),
                                                                onTap: () {
                                                                  setState(() {
                                                                    selectedFontStyle = fontStyles[index];
                                                                    saveColorsToFirestore(userSelectedTextColor,userSelectedBgColor);
                                                                  });
                                                                  Navigator.pop(context);
                                                                  Navigator.pop(context);
                                                                },
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                                child: const Text('Edit Font Style', style: TextStyle(color: primaryColor)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ],
                                      ), 
                                      ),
                                 ] ),
                                  Row(
                                    mainAxisAlignment:MainAxisAlignment.spaceEvenly,
                                    children: [
                                      VideoPlayingIconsWidget(
                                        visible: isControlVisible,
                                        icon: Icons.fast_rewind,
                                        onPressed: () {
                                          controller?.seekTo(Duration(seconds: controller!.value.position.inSeconds -5));
                                        },
                                      ),
                                      if (isLocalStorageVideo)
                                        VideoPlayingIconsWidget(
                                          visible: isControlVisible,
                                          icon: isVideoPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
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
                                        onPressed: () {
                                          controller?.seekTo(Duration(
                                              seconds: controller!.value
                                                      .position.inSeconds +
                                                  5));
                                        },
                                      ),
                                    ],
                                  ),
                                  if (isLocalStorageVideo)
                                    VideoDurationShowWidget(
                                      visible: isControlVisible,
                                      text:"${_formatDuration(controller!.value.position)} / ${_formatDuration(videoDuration)}",
                                    ),
                                     if (!isLocalStorageVideo)
                                    VideoDurationShowWidget(
                                      visible: isControlVisible,
                                      text:"${_formatDuration(youtubeController!.value.position)} / ${_formatDuration(videoDuration)}",
                                    ),
                                  if (isLocalStorageVideo)
                                    VideoAudioIconWidget(
                                      visible: isControlVisible,
                                      isAudioMuted: isAudioMuted,
                                      onPressed: () {
                                        setState(() {
                                          if (isAudioMuted) {
                                            controller?.setVolume(1.0);
                                          } else {
                                            controller?.setVolume(0.0);
                                          }
                                          isAudioMuted = !isAudioMuted;
                                        });
                                      },
                                    ),
                                  if (!isLocalStorageVideo)
                                    VideoAudioIconWidget(
                                      visible: isControlVisible,
                                      isAudioMuted: isAudioMuted,
                                      onPressed: () {
                                        setState(() {
                                          if (isAudioMuted) {
                                            youtubeController?.setVolume(1);
                                          } else {
                                            youtubeController?.setVolume(0);
                                          }
                                          isAudioMuted = !isAudioMuted;
                                        });
                                      },
                                    ),
                                  if (isLocalStorageVideo)
                                    Visibility(
                                      visible: isControlVisible,
                                      child: Positioned(
                                          bottom: 10,
                                          left: 20,
                                          right: 20,
                                          child: buildIndicator()),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          if (isLocalStorageVideo)
                            ElevatedButtonCircularWidget(
                              onPressed: () async {
                                // saveRemainingTime(durationInSeconds, email);
                                if (remainingTime <= videoDuration.inSeconds) {
                                  showLimitAlert(context);
                                } else {
                                  if (isLocalStorageVideo) {
                                    extractAudioFromVideo();
                                  } else {
                                    // downloadVideo();
                                  }
                                }
                              },
                              backgroundColor: primaryColor,
                              child: const RowWithIconTextWidget(
                                text: createSubtitleString,
                                icon: Icons.closed_caption,
                                iconColor: whiteColor,
                                textColor: whiteColor,
                                fontSize: 20,
                              ),
                            ),
                          const SizedBox(height: 10),
                          if (!isLocalStorageVideo)
                            ElevatedButtonCircularWidget(
                              onPressed: () async {

                                downloadYoutubeVideo();
                                fetchVideoInfoAndExtractAudio(
                                    urlController.text);
                              },
                              backgroundColor: primaryColor,
                              child: const RowWithIconTextWidget(
                                text: createSubtitleString,
                                icon: Icons.closed_caption,
                                iconColor: whiteColor,
                                textColor: whiteColor,
                                fontSize: 20,
                              ),
                            ),
                          const SizedBox(height: 10),
                          Column(
                            children: [
                              if (isGettingKey || isTranscribing)
                                const Center(child: LoadingScreen(text: createSubtitlesLoadingMsg,textColor: primaryColor,))
                              else if (subtitles.isNotEmpty)
                                if (isLocalStorageVideo)
                                  Container(
                                    margin: const EdgeInsets.all(10),
                                    decoration: boxDecoration,
                                    child: Column(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.all(10),
                                          height: height/2,
                                          child: ListView.builder(
                                            itemCount: subtitleLines.length,
                                            itemBuilder: (context, index) {
                                              String text =subtitleLines[index]['text'];
                                              double start =subtitleLines[index]['start'] *1000;
                                              double end = subtitleLines[index]['end'] *1000;
                                              Duration currentPosition =controller!.value.position;
                                              bool isHighlighted =currentPosition.inMilliseconds >=start &&currentPosition.inMilliseconds <=end;
                                              TextEditingController subtitleController =TextEditingController(text: text);
                                                                                
                                              // Move the cursor to the end of the text when editing
                                              if (isEditing && isHighlighted) {
                                                final newCursorPosition =subtitleController.text.length;
                                                subtitleController.selection =TextSelection.fromPosition(TextPosition(offset:newCursorPosition));
                                              }
                                                                                
                                              return Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration:BoxDecoration(
                                                  color: isHighlighted ? primaryColor : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: isHighlighted? MainAxisAlignment.center: MainAxisAlignment.center,
                                                  children: [
                                                    Flexible(
                                                      child: isEditing && isHighlighted
                                                          ? TextField(
                                                            decoration: InputDecoration(
                                                              border:InputBorder.none,
                                                              suffixIcon: IconButton(
                                                                onPressed:() async{
                                                                    setState(() {
                                                                      isVideoPlaying = true;
                                                                      controller?.play();
                                                                      isEditing=false;
                                                                      // Get.back();
                                                                    });
                                                                },
                                                                icon:const Icon(Icons.check,color: whiteColor,)
                                                               )
                                                              ),
                                                            controller:subtitleController,
                                                            onChanged:(newText) {
                                                              setState(() {
                                                                subtitleLines[index]['text'] =newText;
                                                              });
                                                            },
                                                            style: const TextStyle(
                                                              color: whiteColor,
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            
                                                          )
                                                          : SelectableText(
                                                                  text,
                                                                  style: TextStyle(
                                                                    backgroundColor: isHighlighted?primaryColor:whiteColor,
                                                                    fontSize:isHighlighted? 16: 14,
                                                                    color: isHighlighted? whiteColor: blackColor,
                                                                    fontWeight:isHighlighted? FontWeight.bold: FontWeight.normal,
                                                                  ),
                                                                ),
                                                                
                                                    ),
                                                    if(isHighlighted && !isEditing)
                                                                IconButton(
                                                                  onPressed:(){
                                                                     setState(() {
                                                                      if(isHighlighted){
                                                                        isEditing = true;
                                                                        isVideoPlaying = false;
                                                                        controller?.pause();
                                                                      }
                                                                    });
                                                                  },
                                                                  icon:const Icon(Icons.edit,color: whiteColor,size: 16,)
                                                                  ),
                                                    const SizedBox(height: 15),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        isEditing?
                                             Align(
                                              alignment: Alignment.bottomRight,
                                              child: Container(
                                                margin: const EdgeInsets.only(right: 20,bottom: 10),
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                                                    onPressed: () {
                                                      // Convert the updated subtitleLines list to a JSON string
                                                      String updatedSubtitle = json.encode({'segments': subtitleLines});
                                                    
                                                      // Call the function to save the updated subtitles to Firestore
                                                      saveSubtitleToFirestore(updatedSubtitle);
                                                      setState(() {
                                                        editedSubtitle =updatedSubtitle;
                                                        isVideoPlaying=true;
                                                        controller?.play();
                                                      });
                                                    },
                                                    child: const Text('Save',style: TextStyle(color: whiteColor),),
                                                  ),
                                              ),
                                            )
                                            : const SizedBox(),
                                      ],
                                    ),
                                  ),
                              if (!isLocalStorageVideo)
                                if (subtitles.isNotEmpty)
                                  Container(
                                    height: 200,
                                    margin: const EdgeInsets.all(10),
                                    decoration: boxDecoration,
                                    padding: const EdgeInsets.all(15),
                                    child: ListView.builder(
                                      itemCount: subtitleLines.length,
                                      itemBuilder: (context, index) {
                                        String text =subtitleLines[index]['text'];
                                        double start = subtitleLines[index]['start'] *1000;
                                        double end =subtitleLines[index]['end'] * 1000;
                                        Duration currentPosition =youtubeController!.value.position;
                                        bool isHighlighted = currentPosition.inMilliseconds >=start &&currentPosition.inMilliseconds <=end;
                                        TextEditingController subtitleController =TextEditingController(text: text);
                                        if (isEditing && isHighlighted) {
                                          final newCursorPosition =subtitleController.text.length;
                                          subtitleController.selection =TextSelection.fromPosition(TextPosition(offset:newCursorPosition));
                                        }

                                        return Container(
                                          padding: const EdgeInsets.all(10),
                                            decoration:BoxDecoration(
                                              color: isHighlighted ? primaryColor : Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          child: Row(
                                            mainAxisAlignment: isHighlighted? MainAxisAlignment.center: MainAxisAlignment.center,
                                            children: [
                                              Flexible(
                                                child: isEditing && isHighlighted?
                                                TextField(
                                                            decoration: InputDecoration(
                                                              border:InputBorder.none,
                                                              suffixIcon: IconButton(
                                                                onPressed:() async{
                                                                    setState(() {
                                                                      isVideoPlaying = true;
                                                                      youtubeController?.play();
                                                                      isEditing=false;
                                                                      Get.back();
                                                                    });
                                                                },
                                                                icon:const Icon(Icons.check,color: whiteColor,)
                                                               )
                                                              ),
                                                            controller:subtitleController,
                                                            onChanged:(newText) {
                                                              setState(() {
                                                                subtitleLines[index]['text'] =newText;
                                                              });
                                                            },
                                                            style: const TextStyle(
                                                              color: whiteColor,
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            
                                                          ):
                                                SelectableText(
                                                  text,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize:isHighlighted ? 17 : 14,
                                                    color: isHighlighted? whiteColor: blackColor,
                                                    fontWeight: isHighlighted? FontWeight.bold: FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              if(isHighlighted && !isEditing)
                                                                IconButton(
                                                                  onPressed:(){
                                                                     setState(() {
                                                                      if(isHighlighted){
                                                                        isEditing = true;
                                                                        isVideoPlaying = false;
                                                                        controller?.pause();
                                                                      }
                                                                    });
                                                                  },
                                                                  icon:const Icon(Icons.edit,color: whiteColor,size: 16,)
                                                                  ),
                                              const SizedBox(height: 25)
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  isEditing?
                                             Align(
                                              alignment: Alignment.bottomRight,
                                              child: Container(
                                                margin: const EdgeInsets.only(right: 20,bottom: 10),
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                                                    onPressed: () {
                                                      // Convert the updated subtitleLines list to a JSON string
                                                      String updatedSubtitle = json.encode({'segments': subtitleLines});
                                                    
                                                      // Call the function to save the updated subtitles to Firestore
                                                      saveSubtitleToFirestore(updatedSubtitle);
                                                      setState(() {
                                                        editedSubtitle =updatedSubtitle;
                                                        isVideoPlaying=true;
                                                        youtubeController?.play();
                                                      });
                                                    },
                                                    child: const Text('Save',style: TextStyle(color: whiteColor),),
                                                  ),
                                              ),
                                            )
                                            : const SizedBox(),
                                            const SizedBox(height: 10,),
                                            
                              Container(
                                margin: const EdgeInsets.only(left: 10),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: primaryColor),
                                      ),
                                      child: TextButton(
                                        onPressed: (){
                                          showAlertDialog();
                                        }, 
                                        child: Row(
                                          children: const [
                                            Icon(Icons.close,size: 20,color: primaryColor,),
                                            SizedBox(width: 5,),
                                            Text(discardString,style:TextStyle(color: primaryColor)),
                                          ],
                                        )
                                      ),
                                    ),
                                    const SizedBox(height:10),
                                    if(subtitles.isNotEmpty)
                                    Container(
                                      height: 40,
                                       decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: primaryColor),
                                      ),
                                      child: TextButton(
                                        onPressed: (){
                                          if (isVideoPlaying) {
                                            controller?.pause();
                                            youtubeController!.pause();
                                          }
                                          downloadSRTFile();
                                        }, 
                                        child: Row(
                                          children: const [
                                            Icon(Icons.download_for_offline,size: 20,color: primaryColor,),
                                            SizedBox(width: 5,),
                                            Text('Download SRT File',style:TextStyle(color: primaryColor)),
                                          ],
                                        )
                                      ),
                                    ),
                                    const SizedBox(height:10),
                                    if(subtitles.isNotEmpty)
                                       Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: primaryColor),
                                        ),
                                        child: TextButton(
                                          onPressed:(){
                                            if (isVideoPlaying) {
                                              controller?.pause();
                                            }
                                            downloadVideoWithSubtitles(context);
                                          }, 
                                          child: Row(
                                            children:   const [
                                              Icon(Icons.download,size: 20,color: primaryColor,),
                                              SizedBox(width: 5,),
                                              
                                              Text('Download with subtitle',style:TextStyle(color: primaryColor)),
                                            ],
                                          )
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                            ],
                          ),
                          const SizedBox(height: 10,),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10,),
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
                        // Text(loadingMsg, textAlign: TextAlign.center),
                        // SizedBox(height: 20),
                        LoadingScreen(text: loadingMsg,textColor: primaryColor,),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if(isDownloadingVideo)
              Container(
                color: Colors.black.withOpacity(0.5), // Semi-transparent background color
                child: Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(top: height/2.5),
                  child: const LoadingScreen(text: 'Downloading....',textColor: whiteColor,)),
              ),
            if(isDownloadingSrt)
              Container(
                color: Colors.black.withOpacity(0.5), // Semi-transparent background color
                child: Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(top: height/2.5),
                  child: const LoadingScreen(text: 'Downloading....',textColor: whiteColor,)),
              )
        ]),
      ),
    );
  }

  void showSubtitleSelectionSheet(
    BuildContext context,
  ) {
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
              const RowWithTextIconButtonWidget(
                text: generateSubtitleMsg,
              ),
              const Divider(color: borderColor),
              const SizedBox(height: 20),
              const Text(selectTranslateLanguageMsg,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  if (isLocalStorageVideo)
                    ElevatedButtonWidget(
                      onPressed: () async {
                        Get.back(); // Close the bottom sheet
                        await convertAudioToText(selectedLanguage);
                        saveRemainingTime(durationInSeconds, uid);
                      },
                      backgroundColor: primaryColor,
                      child: const Text(generateSubtitleString),
                    ),
                  const SizedBox(width: 10),
                  if (!isLocalStorageVideo)
                    ElevatedButtonWidget(
                      onPressed: () async {
                        Get.back(); // Close the bottom sheet
                        await convertAudioToText(selectedLanguage);
                        saveRemainingTime(durationInSeconds, uid);
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
                onPressed: () {
                  Get.back();
                },
                backgroundColor: borderColor,
                child: const Text(cancelString,
                    style: TextStyle(color: whiteColor, fontSize: 15))),
            ElevatedButtonWidget(
                onPressed: () {
                  deleteVideo();
                  Get.back();
                },
                backgroundColor: primaryColor,
                child: const Text(yesString,
                    style: TextStyle(color: whiteColor, fontSize: 15))),
          ],
        );
      },
    );
  }

  void showImportUrlSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: false,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(16.0),
            child: Container(
              margin: const EdgeInsets.only(top: 5),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Youtube Video',
                        style: TextStyle(
                            color: primaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                          onPressed: () {
                            Get.back();
                          },
                          icon: const Icon(
                            Icons.close,
                            color: primaryColor,
                          ))
                    ],
                  ),
                  const Divider(
                    color: borderColor,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: urlController,
                    onChanged: (value) {
                      setState(() {
                        videoUrl = value;
                        isVideoExist = false;
                      });
                    },
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                        label: const Text('Import URL'),
                        labelStyle:
                            const TextStyle(color: primaryColor, fontSize: 15),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 18),
                        prefixIcon: const Icon(Icons.link, color: primaryColor),
                        suffixIcon: IconButton(
                            onPressed: () {
                              isLocalStorageVideo = false;
                              Get.back();
                              getYoutubeVideo();
                              setVideoController();
                            },
                            icon: const Icon(Icons.send, color: primaryColor))),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
