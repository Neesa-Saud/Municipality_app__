import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show File, Platform;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloudinary_public/cloudinary_public.dart';

class ReportProblemPage extends StatefulWidget {
  const ReportProblemPage({super.key});

  @override
  _ReportProblemPageState createState() => _ReportProblemPageState();
}

class _ReportProblemPageState extends State<ReportProblemPage> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  File? _image; // Used for mobile platforms
  XFile? _pickedFile; // Used to store the picked file (for both web and mobile)
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Pick image from gallery with permission handling
  Future<void> _pickImage() async {
    // Skip permission handling on web
    if (!kIsWeb) {
      PermissionStatus status;
      if (Platform.isAndroid) {
        status = await Permission.photos.request();
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      } else {
        status = await Permission.photos.request();
      }

      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Please enable in settings.'),
          ),
        );
        openAppSettings();
        return;
      }
    }

    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedFile = pickedFile;
          if (!kIsWeb) {
            _image = File(pickedFile.path); // For mobile, create a File object
          }
          print('Image picked: ${pickedFile.path}');
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No image selected.')));
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  // Upload image to Cloudinary and return the secure URL and publicId
  Future<Map<String, String?>> _uploadImage(XFile image) async {
    try {
      print('Starting image upload to Cloudinary...');
      // Initialize Cloudinary
      final cloudinary = CloudinaryPublic(
        'dlne9uhda',
        'unsigned_municipality',
        cache: false,
      );
      // Replace 'dlne9uhda' with your Cloudinary cloud name
      // Ensure 'unsigned_municipality' is an unsigned upload preset in your Cloudinary account

      // Upload the image
      CloudinaryResponse response;
      if (kIsWeb) {
        // For web, read the image as bytes
        final bytes = await image.readAsBytes();
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            bytes,
            identifier: image.name,
            resourceType: CloudinaryResourceType.Image,
            folder: 'problem_images',
          ),
        );
      } else {
        File file = File(image.path);
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            file.path,
            resourceType: CloudinaryResourceType.Image,
            folder: 'problem_images',
          ),
        );
      }

      // Check if the upload was successful by verifying secureUrl
      if (response.secureUrl.isNotEmpty) {
        String downloadUrl = response.secureUrl;
        String publicId = response.publicId;
        print('Upload successful. URL: $downloadUrl, Public ID: $publicId');
        return {'secureUrl': downloadUrl, 'publicId': publicId};
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
      return {'secureUrl': null, 'publicId': null};
    }
  }

  // Submit problem to Firestore
  Future<void> _submitProblem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? imageUrl;
        String? imagePublicId;

        if (_pickedFile != null) {
          print('Image selected: ${_pickedFile!.path}');
          final uploadResult = await _uploadImage(_pickedFile!);
          imageUrl = uploadResult['secureUrl'];
          imagePublicId = uploadResult['publicId'];
          print('Image URL after upload: $imageUrl, Public ID: $imagePublicId');
        } else {
          print('No image selected');
        }

        try {
          print(
            'Saving to Firestore: title=$title, desc=$description, imageUrl=$imageUrl, imagePublicId=$imagePublicId',
          );
          await FirebaseFirestore.instance.collection('problems').add({
            'title': title,
            'description': description,
            'userId': user.uid,
            'imageUrl': imageUrl,
            'imagePublicId': imagePublicId, // Store the publicId
            'timestamp': FieldValue.serverTimestamp(),
            'status': null, // Set status to null by default
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Problem posted successfully!')),
          );
          Navigator.pop(context);
        } catch (e) {
          print('Firestore error: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to post problem: $e')));
        }
      } else {
        print('No user logged in');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to post.')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  // Build the image preview widget
  Future<Widget> _buildImagePreview() async {
    if (_pickedFile == null) {
      return const Text('No image selected.');
    }

    if (kIsWeb) {
      final bytes = await _pickedFile!.readAsBytes();
      return Image.memory(
        bytes,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) =>
                const Text('Error loading image preview'),
      );
    } else {
      return Image.file(_image!, height: 200, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Problem'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Problem Title'),
                  validator: (value) => value!.isEmpty ? 'Enter a title' : null,
                  onSaved: (value) => title = value!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator:
                      (value) => value!.isEmpty ? 'Enter a description' : null,
                  onSaved: (value) => description = value!,
                ),
                const SizedBox(height: 20),
                FutureBuilder<Widget>(
                  future: _buildImagePreview(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return snapshot.data ?? const Text('No image selected.');
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Pick Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      onPressed: _submitProblem,
                      child: const Text('Post'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
