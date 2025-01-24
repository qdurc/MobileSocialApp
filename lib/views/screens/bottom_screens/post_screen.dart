import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class PostScreen extends StatefulWidget {
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  File? _mediaFile;
  final TextEditingController _captionController = TextEditingController();
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

  Future<void> _uploadPost() async {
    if (_mediaFile == null || _captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecciona un archivo y escribe un pie de foto.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      User? user = _auth.currentUser;
      print('Este es el $user');
      if (user != null) {
        String postId = Uuid().v4();
        String fileName = 'posts/$postId';

        // Subir archivo a Firebase Storage
        UploadTask uploadTask = _storage.ref(fileName).putFile(_mediaFile!);
        TaskSnapshot snapshot = await uploadTask;
        String fileUrl = await snapshot.ref.getDownloadURL();

        // Guardar detalles del post en Firestore
        await _firestore.collection('posts').doc(postId).set({
          'userId': user.uid,
          'username': user.displayName,
          'caption': _captionController.text.trim(),
          'mediaUrl': fileUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Publicación subida con éxito.')),
        );
        setState(() {
          _mediaFile = null;
          _captionController.clear();
        });
      }
    } catch (e) {
      print('Error al subir la publicación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la publicación.')),
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
        title: Text('Crear Publicación'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.blue),
            onPressed: _isUploading ? null : _uploadPost,
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
                color: Colors.grey[200],
                child: _mediaFile != null
                    ? Image.file(_mediaFile!, fit: BoxFit.cover)
                    : Icon(Icons.add_a_photo, color: Colors.grey, size: 50),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                labelText: 'Escribe un pie de foto...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            _isUploading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _uploadPost,
              child: Text('Subir Publicación'),
            ),
          ],
        ),
      ),
    );
  }
}