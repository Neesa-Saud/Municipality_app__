import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/UserPage/Drawer/connection_page.dart';
import '../../function/database_function.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Removed _loadProfileImage call since it’s for image fetching
  }

  Future<void> _updateUsername(String uid, String currentUsername) async {
    final TextEditingController usernameController = TextEditingController(
      text: currentUsername,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Username'),
        content: TextField(
          controller: usernameController,
          decoration: const InputDecoration(hintText: 'Enter new username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () {
              if (usernameController.text.trim().isNotEmpty) {
                Navigator.pop(context, usernameController.text.trim());
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );

    if (result != null && result != currentUsername) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'username': result,
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating username: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('No user logged in');
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    print('Current user UID: ${user.uid}');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        toolbarHeight: 70,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 60,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                      // Removed image upload logic, keeping placeholder
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FutureBuilder<String?>(
                        future: _databaseService.getUsername(user.uid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return const Text(
                              'Unknown User',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          String username = snapshot.data ?? 'User';
                          return Text(
                            username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.mode_edit_outline_outlined,
                          color: Colors.grey,
                        ),
                        highlightColor: Colors.red,
                        splashColor: Colors.black,
                        onPressed: () async {
                          String? currentUsername =
                              await _databaseService.getUsername(user.uid);
                          _updateUsername(user.uid, currentUsername ?? 'User');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConnectionsPage(),
                        ),
                      );
                    },
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('connections')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text(
                            'Connections: Loading...',
                            style: TextStyle(fontSize: 16, color: Colors.blue),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Text(
                            'Connections: Error',
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          );
                        }
                        int connectionCount = snapshot.data?.docs.length ?? 0;
                        return Text(
                          'Connections: $connectionCount',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.grey),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'My Posts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('problems')
                    .where('userId', isEqualTo: user.uid)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('StreamBuilder error: ${snapshot.error}');
                    print('Stack trace: ${snapshot.stackTrace}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Error loading posts'),
                          const SizedBox(height: 10),
                          Text('Details: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    print('No snapshot data');
                    return const Center(child: Text('No data available'));
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    print('No posts found for user: ${user.uid}');
                    return const Center(child: Text('No posts yet.'));
                  }
                  print(
                    'Found ${snapshot.data!.docs.length} posts for user: ${user.uid}',
                  );
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var problem = snapshot.data!.docs[index];
                      print('Post ${index + 1}: ${problem.data()}');
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    problem['title'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    problem['description'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  // Removed image section, keeping layout
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  bool? confirmDelete = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Post'),
                                      content: const Text(
                                        'Are you sure you want to delete this post?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmDelete == true) {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('problems')
                                          .doc(problem.id)
                                          .delete();

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Post deleted successfully',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error deleting post: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
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
      ),
    );
  }
}