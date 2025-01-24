import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'follow_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchTerm = '';

  void _onSearchChanged() {
    setState(() {
      _searchTerm = _searchController.text.trim().toLowerCase();
    });
  }

  Future<List<Map<String, dynamic>>> _searchUsers(String searchTerm) async {
    if (searchTerm.isEmpty) return [];
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('displayName', isGreaterThanOrEqualTo: searchTerm)
        .where('displayName', isLessThanOrEqualTo: '$searchTerm\uf8ff')
        .get();

    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar Usuarios'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _onSearchChanged(),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre de usuario...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _searchUsers(_searchTerm),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      _searchTerm.isEmpty
                          ? 'Introduce un término de búsqueda'
                          : 'No se encontraron usuarios.',
                    ),
                  );
                }

                List<Map<String, dynamic>> users = snapshot.data!;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['profilePicture'] != null
                            ? NetworkImage(user['profilePicture'])
                            : null,
                        child: user['profilePicture'] == null
                            ? Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user['displayName'] ?? 'Usuario'),
                      subtitle: Text(user['email'] ?? ''),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowModule(),
                          ),
                        );
                      },
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
