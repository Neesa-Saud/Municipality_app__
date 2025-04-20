import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConnectionsPage extends StatelessWidget {
  const ConnectionsPage({super.key});

  // Function to remove a connection
  Future<void> _removeConnection(
    String currentUserId,
    String connectedUserId,
    BuildContext context,
  ) async {
    try {
      // Remove the connection from the current user's connections
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('connections')
          .doc(connectedUserId)
          .delete();

      // Remove the connection from the connected user's connections
      await FirebaseFirestore.instance
          .collection('users')
          .doc(connectedUserId)
          .collection('connections')
          .doc(currentUserId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing connection: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view connections')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Connections',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        toolbarHeight: 70,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('connections')
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print('StreamBuilder error for connections: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Error loading connections'),
                    const SizedBox(height: 10),
                    Text('Details: ${snapshot.error}'),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              print('No connections found for user: ${currentUser.uid}');
              return const Center(child: Text('No connections yet.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var connection = snapshot.data!.docs[index];
                String connectedUserId = connection['connectedUserId'];

                return FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(connectedUserId)
                          .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          child: CircularProgressIndicator(),
                        ),
                        title: Text('Loading...'),
                      );
                    }
                    if (userSnapshot.hasError || !userSnapshot.hasData) {
                      return const ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          child: Icon(Icons.error, color: Colors.red),
                        ),
                        title: Text('Error loading user'),
                      );
                    }

                    var userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    String username = userData?['username'] ?? 'Unknown User';
                    String? profileImageUrl = userData?['profileImageUrl'];

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 16.0,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage:
                              profileImageUrl != null
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                          child:
                              profileImageUrl == null
                                  ? const Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                        title: Text(
                          username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                bool? confirmDelete = await showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Remove Connection'),
                                        content: Text(
                                          'Are you sure you want to remove $username from your connections?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text(
                                              'Remove',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirmDelete == true) {
                                  await _removeConnection(
                                    currentUser.uid,
                                    connectedUserId,
                                    context,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
