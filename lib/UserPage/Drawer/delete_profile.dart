import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteProfilePage extends StatefulWidget {
  const DeleteProfilePage({super.key});

  @override
  State<DeleteProfilePage> createState() => _DeleteProfilePageState();
}

class _DeleteProfilePageState extends State<DeleteProfilePage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isDeleting = false;

  Future<void> _deleteAccount() async {
    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password.')),
      );
      return;
    }

    setState(() => _isDeleting = true);
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No logged-in user or user email is missing.');
      }

      // Re-authenticate with entered password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);

      // Delete user's Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Optionally delete user's posts:
      var posts =
          await FirebaseFirestore.instance
              .collection('problems')
              .where('userId', isEqualTo: user.uid)
              .get();
      for (var doc in posts.docs) {
        await doc.reference.delete();
      }

      // Delete the Firebase Auth account
      await user.delete();

      // Sign out and navigate to login
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully.')),
        );
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String msg = switch (e.code) {
        'wrong-password' => 'Incorrect password. Please try again.',
        'requires-recent-login' =>
          'Please log in again to delete your account.',
        _ => 'Error: ${e.message}',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting account: $e')));
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter your password to delete your account.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            _isDeleting
                ? CircularProgressIndicator(color: Colors.redAccent.shade700)
                : ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete My Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  onPressed: _deleteAccount,
                ),
          ],
        ),
      ),
    );
  }
}
