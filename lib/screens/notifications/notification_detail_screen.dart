import 'package:flutter/material.dart';

class NotificationDetailScreen extends StatelessWidget {
  final String notificationTitle;
  final String notificationBody;

  const NotificationDetailScreen({
    Key? key,
    required this.notificationTitle,
    required this.notificationBody,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(notificationTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notificationTitle,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(notificationBody),
          ],
        ),
      ),
    );
  }
}