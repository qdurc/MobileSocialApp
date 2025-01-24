import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intec_social_app/views/screens/auth/login_screen.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser(
      BuildContext context, email, String password,String phone,String name, String lastname) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'displayName': name.trim(),
        'lastName': lastname.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      Fluttertoast.showToast(
          msg: "Cuenta creada con éxito!", toastLength: Toast.LENGTH_SHORT);

      //Podemos redirigir a la pantalla de login
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return LoginScreen();

      }));
    } catch (e) {
     print('Error desconocido: $e');
      Fluttertoast.showToast(
          msg: "Error: ${e.toString()}", toastLength: Toast.LENGTH_SHORT);
    }
  }

  //Metodo basico para el login del usuario

  Future<void> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = userCredential.user;

      // Verifica si el displayName no está configurado y lo actualizas
      if (user != null && (user.displayName == null || user.displayName!.isEmpty)) {
        // Obtén el nombre de usuario desde Firestore (si lo guardaste allí)
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          String? username = userData['displayName'];

          if (username != null) {
            await user.updateDisplayName(username); // Actualiza el displayName
            await user.reload(); // Recarga los datos del usuario
          }
          print("El user ta ready: $user");
        }
      }
      Fluttertoast.showToast(
          msg: "Bienvenido de Nuevo!", toastLength: Toast.LENGTH_SHORT);
      //Llevar al usuario al Home
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error: ${e.toString()}", toastLength: Toast.LENGTH_SHORT);
    }
  }
}
