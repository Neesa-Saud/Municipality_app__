import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:myapp/utils/extensions.dart'; // Import the shared extension
import 'package:http/http.dart' as http; // Import http package for API calls
import 'dart:convert'; // For encoding credentials

class CompletedPage extends StatelessWidget {
  const CompletedPage({super.key});

  // Cloudinary credentials for deletion (ideally move to a backend)
  final String cloudName = 'dlne9uhda'; // Replace with your actual cloud name
  final String apiKey = '871241446667216'; // Replace with your actual API Key
  final String apiSecret =
      'c5h3QPC4immYhar1iozPzymATu8'; // Replace with your actual API Secret

  // Function to format timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, yyyy hh:mm a').format(dateTime);
  }

  // Function to extract publicId from Cloudinary URL
  String _extractPublicId(String imageUrl) {
    // Example URL: https://res.cloudinary.com/myapp/image/upload/images/problem123.jpg
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    // The publicId is the last segment without the file extension
    final fileName = pathSegments.last;
    final publicIdWithExtension = fileName.split('.');
    final publicId = publicIdWithExtension[0];
    // Include the folder path if it exists (e.g., 'images/problem123')
    final folderIndex =
        pathSegments.indexOf('image') + 2; // Skip 'image/upload'
    final folderPath = pathSegments
        .sublist(folderIndex, pathSegments.length - 1)
        .join('/');
    return '$folderPath/$publicId';
  }

  // Function to delete an image from Cloudinary using the API
  Future<void> _deleteImageFromCloudinary(String publicId) async {
    final url =
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload/destroy';
    final body = {'public_id': publicId};

    // Create Basic Auth header
    final auth = base64Encode(utf8.encode('$apiKey:$apiSecret'));
    final headers = {
      'Authorization': 'Basic $auth',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['result'] == 'ok') {
          print('Image deleted successfully: $publicId');
        } else {
          throw Exception('Failed to delete image: ${response.body}');
        }
      } else {
        throw Exception(
          'Failed to delete image: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting image from Cloudinary: $e');
    }
  }

  // Function to delete a problem
  Future<void> _deleteProblem(
    String problemId,
    String? imageUrl,
    BuildContext context,
  ) async {
    try {
      // Delete the problem document from Firestore
      await FirebaseFirestore.instance
          .collection('problems')
          .doc(problemId)
          .delete();

      // If there's an image, delete it from Cloudinary
      if (imageUrl != null) {
        final publicId = _extractPublicId(imageUrl);
        await _deleteImageFromCloudinary(publicId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Problem deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting problem: $e')));
    }
  }

  // Function to fetch the username of the user who posted the problem
  Future<String> _getUsername(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (userDoc.exists) {
        return (userDoc.data() as Map<String, dynamic>)['username'] ??
            'Unknown User';
      }
      return 'Unknown User';
    } catch (e) {
      print('Error fetching username: $e');
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Completed Problems',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('problems')
                      .where('status', isEqualTo: 'completed')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('StreamBuilder error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Error loading completed problems'),
                        const SizedBox(height: 10),
                        Text('Details: ${snapshot.error}'),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print('No completed problems found');
                  return const Center(child: Text('No completed problems.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var problem = snapshot.data!.docs[index];
                    String problemId = problem.id;
                    String title = problem['title'] ?? 'No Title';
                    String description =
                        problem['description'] ?? 'No Description';
                    String? imageUrl = problem['imageUrl'];
                    String userId = problem['userId'];
                    String status = problem['status'] as String;

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.redAccent.shade700,
                                      ),
                                      onPressed: () async {
                                        bool? confirmDelete = await showDialog(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text(
                                                  'Delete Problem',
                                                ),
                                                content: const Text(
                                                  'Are you sure you want to delete this problem?',
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
                                                    child: Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color:
                                                            Colors
                                                                .redAccent
                                                                .shade700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        );

                                        if (confirmDelete == true) {
                                          await _deleteProblem(
                                            problemId,
                                            imageUrl,
                                            context,
                                          );
                                        }
                                      },
                                      tooltip: 'Delete Problem',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<String>(
                              future: _getUsername(userId),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text(
                                    'Posted by: Loading...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  );
                                }
                                if (userSnapshot.hasError) {
                                  return const Text(
                                    'Posted by: Error',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  );
                                }
                                return Text(
                                  'Posted by: ${userSnapshot.data}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: ${status.capitalize()}',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    status == 'completed'
                                        ? Colors.green
                                        : Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Posted on: ${_formatTimestamp(problem['timestamp'])}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (imageUrl != null) ...[
                              const SizedBox(height: 12),
                              Image.network(
                                imageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return  Text(
                                    'Error loading image',
                                    style: TextStyle(color: Colors.redAccent.shade700),
                                  );
                                },
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
    );
  }
}
