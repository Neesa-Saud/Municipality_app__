import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ReportProblemPage extends StatefulWidget {
  const ReportProblemPage({super.key});

  @override
  _ReportProblemPageState createState() => _ReportProblemPageState();
}

class _ReportProblemPageState extends State<ReportProblemPage> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  bool _isLoading = false;
  File? _capturedImage;

  Future<void> _captureImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _capturedImage = File(picked.path);
        });
      }
    } catch (e) {
      print('Camera error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to open camera')));
    }
  }

  Future<String> uploadImageToCloudinary(File imageFile) async {
    final cloudName =
        'dlne9uhda'; // TODO: Replace with your Cloudinary cloud name
    final uploadPreset =
        'muntipality_app'; // TODO: Replace with your unsigned upload preset

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/dlne9uhda/image/upload',
    );

    final request =
        http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(
            await http.MultipartFile.fromPath('file', imageFile.path),
          );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseString = await response.stream.bytesToString();
      final responseJson = json.decode(responseString);
      return responseJson['secure_url']; // This is the image URL to save in Firestore
    } else {
      throw Exception('Failed to upload image to Cloudinary');
    }
  }

  Future<void> _submitProblem() async {
    if (_formKey.currentState!.validate()) {
      if (_capturedImage == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please capture a photo')));
        return;
      }

      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final imageUrl = await uploadImageToCloudinary(_capturedImage!);

          await FirebaseFirestore.instance.collection('problems').add({
            'title': title,
            'description': description,
            'imageUrl': imageUrl,
            'userId': user.uid,
            'timestamp': FieldValue.serverTimestamp(),
            'status': null,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your problem has been posted successfully!'),
            ),
          );
          Navigator.pop(context);
        } catch (e) {
          print('Upload or Firestore error: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to post problem: $e')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to post.')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildImagePreview() {
    if (_capturedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _capturedImage!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Center(
          child: Text(
            'No photo captured yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Problem'),
        backgroundColor: Colors.redAccent.shade700,
        elevation: 0,
        toolbarHeight: 90,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildImagePreview(),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _captureImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: inputDecoration.copyWith(
                    labelText: 'Problem Title',
                  ),
                  validator:
                      (value) => value!.isEmpty ? 'Please enter a title' : null,
                  onSaved: (value) => title = value!,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: inputDecoration.copyWith(
                    labelText: 'Description',
                  ),
                  maxLines: 4,
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Please enter a description' : null,
                  onSaved: (value) => description = value!,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      onPressed: _submitProblem,
                      child: const Text(
                        'Post Problem',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
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
