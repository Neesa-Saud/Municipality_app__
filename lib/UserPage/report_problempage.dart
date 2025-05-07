import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Submit problem to Firestore
  Future<void> _submitProblem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          print('Saving to Firestore: title=$title, desc=$description');
          await FirebaseFirestore.instance.collection('problems').add({
            'title': title,
            'description': description,
            'userId': user.uid,
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
                const SizedBox(
                  height: 20,
                ), // Placeholder for removed image preview
                const SizedBox(
                  height: 20,
                ), // Placeholder for removed pick image button
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
