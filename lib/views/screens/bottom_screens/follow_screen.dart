import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FollowModule extends StatefulWidget {
  @override
  _FollowModuleState createState() => _FollowModuleState();
}

class _FollowModuleState extends State<FollowModule> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _followUser(String userId) async {
    User? user = _auth.currentUser;
    if (user == null || userId == user.uid) return;

    final currentUserDoc = _firestore.collection('users').doc(user.uid);
    final targetUserDoc = _firestore.collection('users').doc(userId);

    await currentUserDoc.update({
      'following': FieldValue.arrayUnion([userId]),
    });

    await targetUserDoc.update({
      'followers': FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> _unfollowUser(String userId) async {
    User? user = _auth.currentUser;
    if (user == null || userId == user.uid) return;

    final currentUserDoc = _firestore.collection('users').doc(user.uid);
    final targetUserDoc = _firestore.collection('users').doc(userId);

    await currentUserDoc.update({
      'following': FieldValue.arrayRemove([userId]),
    });

    await targetUserDoc.update({
      'followers': FieldValue.arrayRemove([user.uid]),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Usuarios',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No se encontraron usuarios.'));
          }

          User? currentUser = _auth.currentUser;
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final user = snapshot.data!.docs[index];
              final userData = user.data() as Map<String, dynamic>;

              // Ocultar el usuario actual de la lista
              if (currentUser?.uid == user.id) {
                return const SizedBox.shrink();
              }

              final bool isFollowing =
              (userData['followers'] ?? []).contains(currentUser?.uid);

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
                trailing: ElevatedButton(
                  onPressed: isFollowing
                      ? () => _unfollowUser(user.id)
                      : () => _followUser(user.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.grey[400] : Colors.blue,
                  ),
                  child: Text(
                    isFollowing ? 'Siguiendo' : 'Seguir',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
