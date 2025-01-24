import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intec_social_app/views/screens/bottom_screens/story_screen.dart';
import 'package:intec_social_app/views/screens/bottom_screens/viewstory_screen.dart';
import 'comment_screen.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mapa para almacenar las URLs de las imágenes de perfil de los usuarios.
  Map<String, String?> _profilePictures = {};

  Future<void> _toggleLike(String postId, List likes) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    if (likes.contains(user.uid)) {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayRemove([user.uid])
      });
    } else {
      await _firestore.collection('posts').doc(postId).update({
        'likes': FieldValue.arrayUnion([user.uid])
      });
    }
  }

  Future<String?> _getProfilePicture(String userId) async {
    // Verificar si ya tenemos la URL en el mapa.
    if (_profilePictures.containsKey(userId)) {
      return _profilePictures[userId];
    }

    // Si no la tenemos, hacer la consulta.
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>?;
        String? profilePicUrl = userData?['profilePicture'];
        // Almacenar la URL en el mapa para uso futuro.
        _profilePictures[userId] = profilePicUrl;
        return profilePicUrl;
      }
    } catch (e) {
      print("Error al obtener la imagen de perfil: $e");
    }
    return null;
  }

  Widget _buildStoriesCarousel() {
    return StreamBuilder(
      stream: _firestore
          .collection('stories')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No hay historias aún.'));
        }

        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final story = snapshot.data!.docs[index];
              final data = story.data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () {
                  // Navegar a la pantalla de visualización de historia
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewStoryScreen(
                        mediaUrl: data['mediaUrl'],
                        username: data['username'] ?? 'Usuario',
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.all(8.0),
                  width: 80,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: data['mediaUrl'] != null
                            ? NetworkImage(data['mediaUrl'])
                            : null,
                        child: data['mediaUrl'] == null
                            ? Icon(Icons.person, size: 40)
                            : null,
                      ),
                      SizedBox(height: 4),
                      Text(
                        data['username'] ?? 'Usuario',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feed'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.add_a_photo, color: Colors.blue),
            onPressed: () {
              // Navegar a la pantalla de historias
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStoriesCarousel(),
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('posts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No hay publicaciones aún.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final post = snapshot.data!.docs[index];
                    final data = post.data() as Map<String, dynamic>;
                    final likes = List<String>.from(data['likes'] ?? []);
                    final userId = data['userId'];

                    return Card(
                      margin: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<String?>(
                            future: _getProfilePicture(
                                userId), // Obtiene la URL de la imagen de perfil
                            builder: (context, snapshot) {
                              if (snapshot.hasError || !snapshot.hasData) {
                                return CircleAvatar(
                                    child: Icon(Icons
                                        .person)); // Si hay error o no hay datos
                              }

                              return CircleAvatar(
                                backgroundImage: NetworkImage(snapshot.data!),
                              );
                            },
                          ),
                          ListTile(
                            title: Text(data['username'] ?? 'Usuario'),
                            subtitle: Text(data['caption'] ?? ''),
                          ),
                          if (data['mediaUrl'] != null)
                            Image.network(data['mediaUrl'], fit: BoxFit.cover),
                          Row(
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
                                onPressed: () => _toggleLike(post.id, likes),
                              ),
                              Text('${likes.length} Me gusta'),
                              Spacer(),
                              IconButton(
                                icon: Icon(Icons.comment),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CommentsScreen(postId: post.id),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
