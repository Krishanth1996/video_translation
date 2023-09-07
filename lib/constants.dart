import 'package:flutter/material.dart';
import 'package:video_subtitle_translator/colors.dart';

//Images//
const String googleImg = "assets/googlecolor.png";
const String logoImg = "assets/logo.png";
const String importImg = "assets/import.png";
//Web//
const String webbgimg = "assets/loginpageimg_1-transformed.png";
const String privacystring = 'Privacy Policy';
const String termsstring = 'Terms of Use - ';
const String footernamestring = 'Video - Subtitle - Generator';
const String findusonstring = 'Find us on';
const String kelaxastring = '2023 Kelaxa';
const String sureMsg = "Are you sure!";

//Text//
const String appNameString = "Video Translator";
const String phoneNoString = "Phone Number";
const String emailAddString = "Email Address";
const String loginString = "Login";
const String signInGoogleString = "Sign in with Google";
const String profileString = "My Profile";
const String languageString = "Language";
const String logoutString = "Logout";
const String createSubtitleString = "Create Subtitle";
const String importVideoString = "Import video";
const String importUrlString = "Import URL";
const String cancelString = "Cancel";
const String confirmString = "Confirm";
const String attemptLogoutString = "Attempting to Logout!";
const String downloadSRTString = "Subtitle File";
const String userProfileString = "User Profile";
const String emailString = "Email:";
const String nameString = "Name:";
const String phoneString = "Phone Number:";
const String verifyString = "Verify";
const String deleteAccString = "Delete Account";
const String discardString = "Discard";
const String yesString = "Yes";
const String noString = "No";
const String closeString = "Close";
const String generateSubtitleString = "Generate Subtitle";
const String okString = "Ok";
const String nextString = "Next";
const String enterNumberString = "Enter your phone number";
const String enterEmailString = "Enter your email address";

//Messages//
const String importVideoUrlMsg = "Import your video URL";
const String subtitleCreateSuccessMsg = "Successfully created subtitles";
const String srtFileCreateSuccessMsg = "SRT file successfully downloaded";
const String srtFileCreateFailMsg = "Error occured in downloading SRT file";
const String signInSuccessMsg = "Logged In!";
const String selectVideoMsg = "Please select a video first";
const String emptyMsg = "Empty";
const String nameEmptyMsg = "Name is Empty";
const String askLogoutMsg = "Are you sure you want to logout?";
const String loadingMsg ="Do not close this page, we are importing the video from your device!..";
const String select60MVideMsg ="Please select a video with 60 seconds or less.";
const String noEmailMsg = "Email is not available";
const String noNameMsg = "Name is not available";
const String noNumberMsg = "Phone Number is not available";
const String askTranslateNowMsg = "Do you want to translate this video now?";
const String generateSubtitleMsg = "Generate Subtitle to this video";
const String selectTranslateLanguageMsg = "Select Your Translate Language";
const String selectLanguageMsg = "Select the language you wants";
const String translationMsg ="You can translate video to English and same language only";
const String enterFieldsMsg = "You should enter this required field";
const String thankyouMsg = "Thank You";
const String sorryMsg = "Sorry!";
const String phoneNoUpdateSuccessMsg = "Phone Number Successfully Updated";
const String notAbleCreateSubtitleMsg = "Unable to create subtitles";
const String confirmRemoveMsg = "Are you sure you want to remove this item?";
const String invalidUrlMsg = "Invalid YouTube URL";
const String enterUrlMsg = "Please enter a valid YouTube URL";
const String videoDownloadMsg = "Video Downloaded";
const String videoDownloadFailMsg = "Video Downloading failed";
const String createSubtitlesLoadingMsg = "Creating Subtitles...";
const String codeIncorrectMsg ='Verification code in incorrect';
const String tryAgainMsg ='Please try again';





BoxDecoration boxDecoration = BoxDecoration(
  border: Border.all(width: 1, color: whiteColor),
  color: whiteColor,
  borderRadius: BorderRadius.circular(10.0),
  boxShadow: const [
    BoxShadow(
      color: Colors.grey,
      blurRadius: 5.0,
      offset: Offset(0, 3),
    ),
  ],
);

BoxDecoration boxDecoration1 = BoxDecoration(
  border: Border.all(color: lightPurpleColor)

);

BoxDecoration boxDecoration2 = BoxDecoration(
  border: Border.all(color: primaryColor),
    color:lightPurpleColor);