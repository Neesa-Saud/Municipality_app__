// lib/function/database_function.dart
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  // Save user data during signup
  Future<String?> saveUserData(String username, String email) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': username,
          'email': email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return null; // Success
      }
      return 'No user logged in';
    } catch (e) {
      return 'Error saving user data: $e';
    }
  }

  // Fetch username by UID (optional, for later use)
  Future<String?> getUsername(String uid) async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc['username'] as String?;
      }
      return null; // No username found
    } catch (e) {
      print('Error fetching username: $e');
      return null;
    }
  }
}
