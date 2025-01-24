import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  CommentsScreen({required this.postId});

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _commentController = TextEditingController();

  Future<void> _addComment(String text) async {
    User? user = _auth.currentUser;
    if (user != null && text.isNotEmpty) {
      await _firestore.collection('posts').doc(widget.postId).collection('comments').add({
        'userId': user.uid,
        'username': user.displayName ?? 'Usuario',
        'comment': text.trim(),
        'likes': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    }
  }

  Future<void> _toggleLike(String commentId, List likes) async {
    User? user = _auth.currentUser;
    if (user != null) {
      if (likes.contains(user.uid)) {
        await _firestore
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(commentId)
            .update({
          'likes': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        await _firestore
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(commentId)
            .update({
          'likes': FieldValue.arrayUnion([user.uid]),
        });
      }
    }
  }

  Future<String?> _getProfilePicture(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>?;
        return userData?['profilePicture'];
      }
    } catch (e) {
      debugPrint("Error al obtener la imagen de perfil: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comentarios', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildCommentsList(),
          ),
          const Divider(),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder(
      stream: _firestore
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay comentarios aún.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final comment = snapshot.data!.docs[index];
            final data = comment.data() as Map<String, dynamic>;
            final likes = List<String>.from(data['likes'] ?? []);
            final userId = data['userId'];

            return ListTile(
              leading: FutureBuilder<String?>(
                future: _getProfilePicture(userId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircleAvatar(child: Icon(Icons.person));
                  }

                  return CircleAvatar(
                    backgroundImage: NetworkImage(snapshot.data!),
                  );
                },
              ),
              title: Text(data['username'] ?? 'Usuario'),
              subtitle: Text(data['comment'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      likes.contains(_auth.currentUser?.uid)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: likes.contains(_auth.currentUser?.uid)
                          ? Colors.red
                          : null,
                    ),
                    onPressed: () => _toggleLike(comment.id, likes),
                  ),
                  Text('${likes.length}'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Escribe un comentario...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: () => _addComment(_commentController.text),
          ),
        ],
      ),
    );
  }
}
