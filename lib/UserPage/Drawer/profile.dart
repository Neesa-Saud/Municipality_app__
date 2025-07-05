import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../function/database_function.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  String? _profileImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    setState(() {
      _profileImageUrl = userDoc['profileImageUrl'] ?? null;
    });
  }

  Future<void> _pickAndUploadImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (pickedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      const uploadPreset = 'muntipality_app'; // replace with your upload preset
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/dlne9uhda/image/upload',
      );

      final request =
          http.MultipartRequest('POST', uri)
            ..fields['upload_preset'] = uploadPreset
            ..files.add(
              await http.MultipartFile.fromPath('file', pickedImage.path),
            );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        final String imageUrl = jsonResponse['secure_url'];

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profileImageUrl': imageUrl,
        }, SetOptions(merge: true));

        setState(() {
          _profileImageUrl = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      } else {
        throw Exception('Cloudinary upload failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _updateUsername(String uid, String currentUsername) async {
    final TextEditingController usernameController = TextEditingController(
      text: currentUsername,
    );

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Update Username'),
            content: TextField(
              controller: usernameController,
              decoration: const InputDecoration(hintText: 'Enter new username'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.redAccent.shade700),
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
          const SnackBar(content: Text('Your username has been updated 😊')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating username: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent.shade700,
        toolbarHeight: 90,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadImage,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                      child:
                          _profileImageUrl == null
                              ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                    if (_isUploading)
                      const CircularProgressIndicator(color: Colors.red),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder<String?>(
                  future: _databaseService.getUsername(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
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
                  onPressed: () async {
                    String? currentUsername = await _databaseService
                        .getUsername(user.uid);
                    _updateUsername(user.uid, currentUsername ?? 'User');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.grey),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'My Posts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('problems')
                        .where('userId', isEqualTo: user.uid)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading posts: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No posts yet.'));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var problem = snapshot.data!.docs[index];
                      final data = problem.data() as Map<String, dynamic>?;

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (data != null &&
                                  data.containsKey('imageUrl') &&
                                  data['imageUrl'] != null &&
                                  data['imageUrl'].toString().isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    data['imageUrl'],
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (data != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  data['title'] ?? 'No Title',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data['description'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Color.fromARGB(255, 255, 1, 1),
                                    ),
                                    onPressed: () async {
                                      bool? confirmDelete = await showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text('Delete Post'),
                                              content: const Text(
                                                'Are you sure you want to delete this post?',
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
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Post deleted successfully',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
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
                            ],
                          ),
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
