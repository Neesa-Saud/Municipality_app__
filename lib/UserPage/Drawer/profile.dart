import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/UserPage/Drawer/connection_page.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../function/database_function.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseService _databaseService = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  bool _isUploading = false;
  String? _profileImageUrl; // To store the Firestore profile image URL
  String? _profileImagePublicId; // To store the Firestore publicId

  @override
  void initState() {
    super.initState();
    _loadProfileImage(); // Load existing profile image on init
  }

  // Load the existing profile image from Firestore
  Future<void> _loadProfileImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userDoc.exists) {
        setState(() {
          _profileImageUrl = userDoc['profileImageUrl'];
          _profileImagePublicId = userDoc['profileImagePublicId'];
        });
      }
    }
  }

  Future<void> _pickProfileImage(User user) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          if (!kIsWeb) {
            _profileImage = File(pickedFile.path);
          }
        });
        await _uploadProfileImage(user.uid, pickedFile);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _uploadProfileImage(String uid, XFile image) async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Check if there's an existing profile image to delete
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      String? existingImagePublicId =
          userDoc.exists && userDoc.data() != null
              ? (userDoc.data() as Map<String, dynamic>)['profileImagePublicId']
              : null;

      if (existingImagePublicId != null) {
        await _deleteImageFromCloudinary(existingImagePublicId);
      }

      print('Starting image upload to Cloudinary...');
      // Initialize Cloudinary
      final cloudinary = CloudinaryPublic(
        'dlne9uhda',
        'unsigned_profile',
        cache: false,
      );
      // Replace 'dlne9uhda' with your Cloudinary cloud name
      // Ensure 'unsigned_profile' is an unsigned upload preset in your Cloudinary account

      // Upload the image
      CloudinaryResponse response;
      if (kIsWeb) {
        // For web, we need to convert XFile to bytes
        final bytes = await image.readAsBytes();
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            bytes,
            identifier: image.name,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
      } else {
        File file = File(image.path);
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            file.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
      }

      // Check if the upload was successful by verifying secureUrl
      if (response.secureUrl.isNotEmpty) {
        String downloadUrl = response.secureUrl;
        String publicId = response.publicId;
        print('Upload successful. URL: $downloadUrl, Public ID: $publicId');

        // Save the image URL and publicId to Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'profileImageUrl': downloadUrl,
          'profileImagePublicId': publicId,
        }, SetOptions(merge: true));

        setState(() {
          _profileImageUrl = downloadUrl;
          _profileImagePublicId = publicId;
          _profileImage = null; // Clear local file after upload
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      } else {
        throw Exception(
          'Failed to upload image to Cloudinary: No secure URL returned',
        );
      }
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _deleteImageFromCloudinary(String publicId) async {
    try {
      print('Deleting image with public ID: $publicId');

      // Call the Cloud Function to delete the image
      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'deleteCloudinaryImage',
      );
      final result = await callable.call(<String, dynamic>{
        'publicId': publicId,
      });

      if (result.data['status'] == 'success') {
        print('Image deleted successfully from Cloudinary');
      } else {
        throw Exception('Failed to delete image: ${result.data['message']}');
      }
    } catch (e) {
      print('Error deleting image from Cloudinary: $e');
      throw e;
    }
  }

  Future<void> _removeProfileImage(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      String? existingImagePublicId =
          userDoc.exists && userDoc.data() != null
              ? (userDoc.data() as Map<String, dynamic>)['profileImagePublicId']
              : null;

      if (existingImagePublicId != null) {
        await _deleteImageFromCloudinary(existingImagePublicId);
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'profileImageUrl': null,
          'profileImagePublicId': null,
        }, SetOptions(merge: true));
        setState(() {
          _profileImage = null;
          _profileImageUrl = null;
          _profileImagePublicId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image removed successfully!')),
        );
      }
    } catch (e) {
      print('Error removing profile image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to remove image: $e')));
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
                      CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            _profileImage != null
                                ? FileImage(_profileImage!)
                                : (_profileImageUrl != null
                                    ? CachedNetworkImageProvider(
                                      _profileImageUrl!,
                                    )
                                    : null),
                        child:
                            _profileImage == null && _profileImageUrl == null
                                ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                                : null,
                      ),
                      if (!_isUploading)
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(60),
                              onTap: () => _pickProfileImage(user),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.4),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_isUploading)
                        const CircularProgressIndicator(color: Colors.white),
                      if (_profileImageUrl != null && !_isUploading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removeProfileImage(user.uid),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.red,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
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
                          String? currentUsername = await _databaseService
                              .getUsername(user.uid);
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
                      stream:
                          FirebaseFirestore.instance
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
                                  if (problem['imageUrl'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: CachedNetworkImage(
                                        imageUrl: problem['imageUrl'],
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) => const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                        errorWidget:
                                            (context, url, error) => const Text(
                                              'Error loading image',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                      ),
                                    ),
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
