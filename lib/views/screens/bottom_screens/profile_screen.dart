import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intec_social_app/views/screens/bottom_screens/userlist_screen.dart';

import 'editprofile_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.data() as Map<String, dynamic>? ?? {};
    }
    return {};
  }

  void _navigateToUserList(BuildContext context, String title, List<String> userIds) {
    if (userIds.isEmpty) {
      // Muestra un mensaje si la lista está vacía
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No hay $title disponibles')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserListScreen(
          title: title,
          userIds: userIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchUserData(),
      builder: (context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error al cargar los datos del usuario')),
          );
        } else {
          // Manejar datos del usuario
          final userData = snapshot.data ?? {};
          final followers = List<String>.from(userData['followers'] ?? []);
          final following = List<String>.from(userData['following'] ?? []);
          final profilePicture = userData['profilePicture'] as String?;
          final displayName = userData['displayName'] as String? ?? 'Usuario';
          final email = userData['email'] as String? ?? '';
          final bio = userData['bio'] as String?; // Bio del usuario

          return Scaffold(
            appBar: AppBar(
              title: Text('Perfil'),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black),
            ),
            body: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Foto de perfil
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage:
                        profilePicture != null ? NetworkImage(profilePicture) : null,
                        child: profilePicture == null
                            ? Icon(Icons.person, color: Colors.grey, size: 50)
                            : null,
                      ),
                      SizedBox(height: 16),

                      // Nombre de usuario
                      Text(
                        displayName,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),

                      // Correo electrónico
                      Text(
                        email,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),

                      // Bio (si existe)
                      if (bio != null && bio.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text(
                          bio,
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      SizedBox(height: 16),

                      // Seguidores y seguidos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _navigateToUserList(
                              context,
                              'Seguidores',
                              followers,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${followers.length}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Seguidores'),
                              ],
                            ),
                          ),
                          SizedBox(width: 24),
                          GestureDetector(
                            onTap: () => _navigateToUserList(
                              context,
                              'Seguidos',
                              following,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${following.length}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Seguidos'),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),
                      Divider(),

                      // Opciones del perfil
                      ListTile(
                        leading: Icon(Icons.edit, color: Colors.blue),
                        title: Text('Editar Perfil'),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(),
                            ),
                          );

                          // Si se devuelve true, recarga los datos del perfil
                          if (result == true) {
                            setState(() {});
                          }
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.logout, color: Colors.red),
                        title: Text('Cerrar Sesión'),
                        onTap: () async {
                          try {
                            await _auth.signOut();
                            if (_auth.currentUser == null) {
                              // Redirigir solo si se cerró la sesión exitosamente
                              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al cerrar sesión')),
                              );
                            }
                          } catch (e) {
                            print('Error al cerrar sesión: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al cerrar sesión: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
