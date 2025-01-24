import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserListScreen extends StatelessWidget {
  final String title;
  final List<String> userIds;

  const UserListScreen({required this.title, required this.userIds});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Caso donde la lista de usuarios está vacía
    if (userIds.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: const Center(
          child: Text(
            'No hay usuarios disponibles.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: userIds)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No se encontraron usuarios.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final userDoc = snapshot.data!.docs[index];
              final userData = userDoc.data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: userData['profilePicture'] != null
                      ? NetworkImage(userData['profilePicture'])
                      : null,
                  child: userData['profilePicture'] == null
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                title: Text(userData['displayName'] ?? 'Usuario'),
                subtitle: Text(userData['email'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
