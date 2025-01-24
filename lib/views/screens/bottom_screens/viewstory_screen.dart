import 'package:flutter/material.dart';

class ViewStoryScreen extends StatelessWidget {
  final String mediaUrl;
  final String username;

  ViewStoryScreen({required this.mediaUrl, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: Image.network(
          mediaUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}