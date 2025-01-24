import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  File? _image;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      Map<String, dynamic> updatedData = {
        'displayName': _usernameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      if (_image != null) {
        try {
          String fileName = 'profile_pictures/${user.uid}.jpg';
          UploadTask uploadTask = _storage.ref(fileName).putFile(_image!);
          TaskSnapshot snapshot = await uploadTask;
          String fileUrl = await snapshot.ref.getDownloadURL();
          updatedData['profilePicture'] = fileUrl;
        } catch (e) {
          debugPrint("Error al subir la imagen: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al subir la imagen.')),
          );
          return;
        }
      }

      try {
        await _firestore.collection('users').doc(user.uid).update(updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado con éxito!')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        debugPrint("Error al actualizar el perfil: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el perfil.')),
        );
      }
    }
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
      if (userData != null) {
        _usernameController.text = userData['displayName'] ?? '';
        _lastNameController.text = userData['lastName'] ?? '';
        _bioController.text = userData['bio'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blue),
            onPressed: _updateProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? const Icon(Icons.camera_alt, size: 30, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _usernameController,
              labelText: 'Nombre de Usuario',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _lastNameController,
              labelText: 'Apellido',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _bioController,
              labelText: 'Biografía',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              labelText: 'Teléfono',
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
