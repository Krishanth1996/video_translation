import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RemainingTimeWidget extends StatelessWidget {
  final String email;

  RemainingTimeWidget(this.email);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('Remaining_Time').doc(email).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Loading indicator while fetching data
        }
        
        if (snapshot.hasError) {
          return const Text('Error loading data'); // Display an error message if something goes wrong
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('No data available'); // Display a message if no data is available
        }

        Map<String, dynamic> dataMap = snapshot.data!.data() as Map<String, dynamic>;
        double remainingTime = dataMap['remainingTime'] as double;

        return Column(
          children: [
            Text('Remaining Time: ${remainingTime.toStringAsFixed(2)} seconds'),
            LinearProgressIndicator(
              value: remainingTime / 900.0, // Assuming the monthly limit is 900 seconds
            ),
          ],
        );
      },
    );
  }
}