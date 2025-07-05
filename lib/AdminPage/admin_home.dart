import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:myapp/AdminPage/completedpage.dart';

import 'package:myapp/AdminPage/pendingpage.dart';
import 'package:myapp/AdminPage/usersid.dart';
import 'package:myapp/utils/extensions.dart'; // Import the shared extension
import 'package:myapp/utils/cloudinary_utils.dart'; // Import the Cloudinary utility

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  final List<Widget> _pages = <Widget>[
    AdminHomeContent(),
    PendingPage(),
    CompletedPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user logged in')));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          icon: const Icon(Icons.density_medium),
        ),
        title: const Text(
          'Welcome Admin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsersPage()),
              );
            },
            tooltip: 'View All Users',
          ),
          const SizedBox(width: 16),
        ],
        backgroundColor: Colors.redAccent.shade700,
        toolbarHeight: 80,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.redAccent.shade700),
              child: Text(
                'Admin Menu',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 0;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Add settings navigation if needed
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Pending',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Completed',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.redAccent.shade700,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class AdminHomeContent extends StatelessWidget {
  const AdminHomeContent({super.key});

  // Function to format timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, yyyy hh:mm a').format(dateTime);
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
        final publicId = CloudinaryUtils.extractPublicId(imageUrl);
        await CloudinaryUtils.deleteImageFromCloudinary(publicId);
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

  // Function to update the status of a problem
  Future<void> _updateProblemStatus(
    String problemId,
    String status,
    String userId,
    String problemTitle,
    BuildContext context,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('problems')
          .doc(problemId)
          .update({'status': status});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'type': 'problem_status_update',
            'problemId': problemId,
            'problemTitle': problemTitle,
            'status': status,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false, // Optional: Mark as unread
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Problem marked as $status')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating problem status: $e')),
      );
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
              'Reported Problems',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('problems')
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
                        const Text('Error loading problems'),
                        const SizedBox(height: 10),
                        Text('Details: ${snapshot.error}'),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print('No problems found in Firestore.');
                  return const Center(child: Text('No problems reported yet.'));
                }

                print('Total problems fetched: ${snapshot.data!.docs.length}');
                // Filter for problems where status is null
                var filteredProblems =
                    snapshot.data!.docs.where((problem) {
                      Map<String, dynamic> problemData =
                          problem.data() as Map<String, dynamic>;
                      // Status is null if the field doesn't exist or is explicitly null
                      bool isStatusNull =
                          !problemData.containsKey('status') ||
                          problemData['status'] == null ||
                          problemData['status'] == 'null'; // Handle edge case
                      print(
                        'Problem ID: ${problem.id}, Status: ${problemData.containsKey('status') ? problemData['status'] : 'not set'}, isStatusNull: $isStatusNull',
                      );
                      return isStatusNull;
                    }).toList();

                if (filteredProblems.isEmpty) {
                  print('No problems passed the filter.');
                  return const Center(
                    child: Text('No new problems to review.'),
                  );
                }

                print('Filtered problems count: ${filteredProblems.length}');
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredProblems.length,
                  itemBuilder: (context, index) {
                    var problem = filteredProblems[index];
                    String problemId = problem.id;
                    String title = problem['title'] ?? 'No Title';
                    String description =
                        problem['description'] ?? 'No Description';
                    String? imageUrl = problem['imageUrl'];
                    String userId = problem['userId'];

                    // Safely access the problem data
                    Map<String, dynamic> problemData =
                        problem.data() as Map<String, dynamic>;
                    // Since filteredProblems only includes problems with status: null,
                    // we can safely set the display status to 'new'
                    String displayStatus = 'new';

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
                                      icon: const Icon(
                                        Icons.access_time,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () async {
                                        bool? confirmUpdate = await showDialog(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text(
                                                  'Mark as Pending',
                                                ),
                                                content: const Text(
                                                  'Are you sure you want to mark this problem as pending?',
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
                                                      'Confirm',
                                                      style: TextStyle(
                                                        color: Colors.orange,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        );

                                        if (confirmUpdate == true) {
                                          await _updateProblemStatus(
                                            problemId,
                                            'pending',
                                            userId,
                                            title,
                                            context,
                                          );
                                        }
                                      },
                                      tooltip: 'Mark as Pending',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                      onPressed: () async {
                                        bool? confirmUpdate = await showDialog(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text(
                                                  'Mark as Completed',
                                                ),
                                                content: const Text(
                                                  'Are you sure you want to mark this problem as completed?',
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
                                                      'Confirm',
                                                      style: TextStyle(
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        );

                                        if (confirmUpdate == true) {
                                          await _updateProblemStatus(
                                            problemId,
                                            'completed',
                                            userId,
                                            title,
                                            context,
                                          );
                                        }
                                      },
                                      tooltip: 'Mark as Completed',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
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
                            FutureBuilder<DocumentSnapshot>(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(userId)
                                      .get(),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Row(
                                    children: [
                                      Text(
                                        'Posted by: ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.grey,
                                              ),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                if (userSnapshot.hasError ||
                                    !userSnapshot.hasData ||
                                    !userSnapshot.data!.exists) {
                                  return const Text(
                                    'Posted by: Unknown User',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  );
                                }

                                final userData =
                                    userSnapshot.data!.data()
                                        as Map<String, dynamic>;
                                final username =
                                    userData['username'] ?? 'Unknown User';
                                final email = userData['email'] ?? 'No Email';
                                final profileImageUrl =
                                    userData['profileImageUrl'];

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(4),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (_) => AlertDialog(
                                              title: const Text(
                                                'User Info',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 40,
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                    backgroundImage:
                                                        profileImageUrl != null
                                                            ? NetworkImage(
                                                              profileImageUrl,
                                                            )
                                                            : null,
                                                    child:
                                                        profileImageUrl == null
                                                            ? const Icon(
                                                              Icons.person,
                                                              size: 40,
                                                              color:
                                                                  Colors.grey,
                                                            )
                                                            : null,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    username,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    email,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: Text(
                                                    'Close',
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
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        'Posted by: $username',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.redAccent.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 4),
                            Text(
                              'Status: ${displayStatus.capitalize()}',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    displayStatus == 'completed'
                                        ? Colors.green
                                        : displayStatus == 'pending'
                                        ? Colors.orange
                                        : Colors.blue, // Blue for "new"
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
                                  return const Text(
                                    'Error loading image',
                                    style: TextStyle(color: Colors.red),
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
