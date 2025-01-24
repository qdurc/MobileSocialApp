import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intec_social_app/views/screens/auth/login_screen.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser(
      BuildContext context,
      String email,
      String password,
      String phone,
      String name,
      String lastname,
      ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _createUserInFirestore(
        userCredential.user?.uid,
        email,
        name,
        lastname,
        phone,
      );

      _showToast("Cuenta creada con éxito!");

      _navigateToLoginScreen(context);
    } catch (e) {
      debugPrint('Error desconocido: $e');
      _showToast("Error: ${e.toString()}");
    }
  }

  Future<void> _createUserInFirestore(
      String? uid,
      String email,
      String name,
      String lastname,
      String phone,
      ) async {
    if (uid != null) {
      await _firestore.collection('users').doc(uid).set({
        'displayName': name.trim(),
        'lastName': lastname.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _navigateToLoginScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Future<void> loginUser(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _updateUserDisplayName(userCredential.user);

      _showToast("Bienvenido de Nuevo!");
    } catch (e) {
      debugPrint('Error de inicio de sesión: $e');
      _showToast("Error: ${e.toString()}");
    }
  }

  Future<void> _updateUserDisplayName(User? user) async {
    if (user != null && (user.displayName == null || user.displayName!.isEmpty)) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final username = userData['displayName'] ?? '';

        if (username.isNotEmpty) {
          await user.updateDisplayName(username);
          await user.reload();
        }
      }
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
    );
  }
}
