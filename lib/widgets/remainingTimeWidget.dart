import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_subtitle_translator/colors.dart';

class RemainingTimeWidget extends StatelessWidget {
  final String? email;

  const RemainingTimeWidget(this.email, {super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Remaining_Time')
          .doc(email)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
              'Error loading data'); // Display an error message if something goes wrong
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text('No data available'),
          );
        }

        Map<String, dynamic> userData =
            snapshot.data!.data() as Map<String, dynamic>;
        double remainingTimeSeconds = userData['remainingTime'] as double;
        double usedTimeInSeconds = userData['usedTime'] as double;
        double monthlyLimitInSeconds = userData['monthlyLimit'] as double;

        double usedTimeInMinutes = usedTimeInSeconds / 60;
        double monthlyLimitInMinutes = monthlyLimitInSeconds / 60;
        double remainingTimeMinutes = remainingTimeSeconds / 60;

        double remainingProgress = remainingTimeSeconds / monthlyLimitInSeconds;
        double usedProgress = usedTimeInSeconds / monthlyLimitInSeconds;
        double usedPercentage = (usedProgress * 100).toDouble();

        String formattedUsedTime = usedTimeInMinutes.toStringAsFixed(2);
        String formattedMonthlyLimit = monthlyLimitInMinutes.toStringAsFixed(2);
        String formattedUsedPercentage = usedPercentage.toStringAsFixed(2);
        String formattedRemainingTime = remainingTimeMinutes.toStringAsFixed(2);

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              width: 300,
              height: 20,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: LinearProgressIndicator(
                  value: usedProgress,
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                  backgroundColor: const Color(0xffD6D6D6),
                ),
              ),
            ),
            Text('Used :$formattedUsedPercentage% - $formattedUsedTime min /$formattedMonthlyLimit min'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('(You have only $formattedRemainingTime minutes)',style: const TextStyle(color: greenColor,fontSize:12,fontWeight: FontWeight.bold)),
              ],
            )
          ],
        );
      },
    );
  }
}
