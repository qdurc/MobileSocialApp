import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _startNewChat(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Verifica si ya existe un chat entre los dos usuarios
    final existingChat = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .get();

    for (var doc in existingChat.docs) {
      final chatParticipants = List<String>.from(doc['participants']);
      if (chatParticipants.contains(userId)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatId: doc.id, otherUserId: userId),
          ),
        );
        return;
      }
    }

    // Si no existe un chat, crea uno nuevo
    final newChatRef = _firestore.collection('chats').doc();
    await newChatRef.set({
      'participants': [currentUser.uid, userId],
      'lastMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: newChatRef.id, otherUserId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar usuarios...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),
        ),
      ),
      body: _searchQuery.isEmpty
          ? _buildChatList(currentUser)
          : _buildSearchResults(),
    );
  }

  Widget _buildChatList(User? currentUser) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay chats disponibles.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final chat = snapshot.data!.docs[index];
            final chatData = chat.data() as Map<String, dynamic>;
            final otherUserId = chatData['participants']
                .firstWhere((id) => id != currentUser?.uid);

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final userData = userSnapshot.data?.data() as Map<String, dynamic>;

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
                  subtitle: Text(chatData['lastMessage'] ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chat.id,
                          otherUserId: otherUserId,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: _searchQuery)
          .where('displayName', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No se encontraron usuarios.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final user = snapshot.data!.docs[index];
            final userData = user.data() as Map<String, dynamic>;

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
              onTap: () => _startNewChat(user.id),
            );
          },
        );
      },
    );
  }
}
