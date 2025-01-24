import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StoryScreen extends StatefulWidget {
  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  File? _mediaFile;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isUploading = false;

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadStory() async {
    if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un archivo para tu historia.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        String storyId = Uuid().v4();
        String fileName = 'stories/$storyId';

        // Subir archivo a Firebase Storage
        UploadTask uploadTask = _storage.ref(fileName).putFile(_mediaFile!);
        TaskSnapshot snapshot = await uploadTask;
        String fileUrl = await snapshot.ref.getDownloadURL();

        // Guardar detalles de la historia en Firestore
        await _firestore.collection('stories').doc(storyId).set({
          'userId': user.uid,
          'username': user.displayName ?? 'Usuario',
          'userProfilePic': user.photoURL,
          'mediaUrl': fileUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historia subida con éxito.')),
        );
        setState(() {
          _mediaFile = null;
        });
      }
    } catch (e) {
      debugPrint('Error al subir la historia: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al subir la historia.')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crear Historia',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blue),
            onPressed: _isUploading ? null : _uploadStory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickMedia,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: _mediaFile != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(_mediaFile!, fit: BoxFit.cover),
                )
                    : const Icon(Icons.add_a_photo, color: Colors.grey, size: 50),
              ),
            ),
            const SizedBox(height: 16),
            _isUploading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _uploadStory,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Subir Historia'),
            ),
          ],
        ),
      ),
    );
  }
}
