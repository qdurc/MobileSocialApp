import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  ChatScreen({required this.chatId, required this.otherUserId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  File? _mediaFile;

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty && _mediaFile == null) return;

    String? mediaUrl;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (_mediaFile != null) {
      try {
        final fileName = 'chats/${widget.chatId}/${Uuid().v4()}';
        final uploadTask = _storage.ref(fileName).putFile(_mediaFile!);
        final snapshot = await uploadTask;
        mediaUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        print("Error al subir el archivo: $e");
        return;
      }
    }

    try {
      // Agregar datos del usuario en el mensaje
      await _firestore.collection('chats').doc(widget.chatId).collection('messages').add({
        'senderId': currentUser?.uid,
        'username': currentUser?.displayName ?? 'Usuario',
        'profilePicture': currentUser?.photoURL,
        'text': text,
        'mediaUrl': mediaUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
      setState(() {
        _mediaFile = null;
      });
    } catch (e) {
      print("Error al enviar mensaje: $e");
    }
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print(snapshot.error);
                  return Center(child: Text('Error al cargar mensajes.'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No hay mensajes aún.'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data!.docs[index];
                    final data = message.data() as Map<String, dynamic>;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: data['profilePicture'] != null
                            ? NetworkImage(data['profilePicture'])
                            : null,
                        child: data['profilePicture'] == null
                            ? Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                      title: Text(data['username'] ?? 'Usuario'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data['mediaUrl'] != null)
                            Image.network(
                              data['mediaUrl'],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          Text(data['text'] ?? '[Mensaje vacío]'),
                          if (data['createdAt'] != null)
                            Text(
                              (data['createdAt'] as Timestamp)
                                  .toDate()
                                  .toLocal()
                                  .toString(),
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.photo),
                onPressed: _pickMedia,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(hintText: 'Escribe un mensaje...'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () => _sendMessage(_messageController.text.trim()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
