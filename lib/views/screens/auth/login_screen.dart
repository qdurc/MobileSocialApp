import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _checkUserLoggedIn();
  }

  // void _checkUserLoggedIn() async {
  //   final user = _auth.currentUser;
  //   if (user != null) {
  //     _navigateToHomeScreen();
  //   }
  // }

  void _navigateToHomeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  Future<void> _loginUser() async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        await _updateUserData(user);
      }

      Fluttertoast.showToast(
        msg: "Bienvenido de nuevo!",
        toastLength: Toast.LENGTH_SHORT,
      );

      _navigateToHomeScreen();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> _updateUserData(User user) async {
    final userDoc =
    await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;

      final username = userData['displayName'] ?? '';
      final profilePic = userData['profilePicture'] ?? '';

      if (username.isNotEmpty) {
        await user.updateDisplayName(username);
      }
      if (profilePic.isNotEmpty) {
        await user.updatePhotoURL(profilePic);
      }

      await user.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Image.asset(
              'assets/Xicon.jpg',
              height: 80,
            ),
            const SizedBox(height: 40),
            _buildTextField(
              controller: _emailController,
              hintText: 'Correo electrónico',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              hintText: 'Contraseña',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildLoginButton(),
            const SizedBox(height: 16),
            _buildRegisterRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      obscureText: obscureText,
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _loginUser,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            'Iniciar sesión',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('¿No tienes una cuenta?'),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegisterScreen()),
            );
          },
          child: const Text('Regístrate'),
        ),
      ],
    );
  }
}



