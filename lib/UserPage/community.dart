import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  // Function to send a connection request
  Future<void> _sendConnectionRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      // Fetch the current user's username
      DocumentSnapshot currentUserDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();

      String currentUsername =
          currentUserDoc.exists
              ? (currentUserDoc.data() as Map<String, dynamic>)['username'] ??
                  'Unknown User'
              : 'Unknown User';

      // Fetch the target user's username
      DocumentSnapshot targetUserDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUserId)
              .get();

      String targetUsername =
          targetUserDoc.exists
              ? (targetUserDoc.data() as Map<String, dynamic>)['username'] ??
                  'Unknown User'
              : 'Unknown User';

      // Check if a request already exists
      QuerySnapshot existingRequests =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUserId)
              .collection('notifications')
              .where('type', isEqualTo: 'connection_request')
              .where('fromUserId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'pending')
              .get();

      if (existingRequests.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection request already sent!'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Send a connection request notification to the target user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .add({
            'type': 'connection_request',
            'fromUserId': currentUserId,
            'fromUsername': currentUsername,
            'toUserId': targetUserId,
            'status': 'pending', // Status: pending, accepted, or rejected
            'timestamp': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection request sent to $targetUsername'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending connection request: $e')),
      );
    }
  }

  // Function to check if users are already connected
  Future<bool> _isConnected(String currentUserId, String targetUserId) async {
    DocumentSnapshot connectionDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('connections')
            .doc(targetUserId)
            .get();
    return connectionDoc.exists;
  }

  // Function to check if a connection request is pending
  Future<bool> _isRequestPending(
    String currentUserId,
    String targetUserId,
  ) async {
    QuerySnapshot pendingRequest =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUserId)
            .collection('notifications')
            .where('type', isEqualTo: 'connection_request')
            .where('fromUserId', isEqualTo: currentUserId)
            .where('status', isEqualTo: 'pending')
            .get();
    return pendingRequest.docs.isNotEmpty;
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view the community')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search by username...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  onChanged: _onSearchChanged,
                )
                : const Text(
                  'Our Community',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
        backgroundColor: Colors.red,
        toolbarHeight: 100,
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(_isSearching ? Icons.close : Icons.search),
          ),
          const SizedBox(width: 30),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No users found.'));
            }

            List<QueryDocumentSnapshot> users = snapshot.data!.docs;

            // Filter and reorder based on search query
            List<QueryDocumentSnapshot> filteredUsers =
                users.where((user) {
                  var userData = user.data() as Map<String, dynamic>;
                  String username =
                      (userData['username'] ?? 'Unknown User').toLowerCase();
                  return username.contains(_searchQuery);
                }).toList();

            // Move exact match to top (if any)
            if (_searchQuery.isNotEmpty) {
              int exactMatchIndex = filteredUsers.indexWhere((user) {
                var userData = user.data() as Map<String, dynamic>;
                return (userData['username'] ?? 'Unknown User').toLowerCase() ==
                    _searchQuery;
              });
              if (exactMatchIndex != -1) {
                var exactMatch = filteredUsers.removeAt(exactMatchIndex);
                filteredUsers.insert(0, exactMatch);
              }
            }

            // If no search query, show all users except current user
            if (_searchQuery.isEmpty) {
              filteredUsers =
                  users.where((user) => user.id != currentUser.uid).toList();
            }

            if (filteredUsers.isEmpty && _searchQuery.isNotEmpty) {
              return const Center(child: Text('No matching users found.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                var user = filteredUsers[index].data() as Map<String, dynamic>;
                String username = user['username'] ?? 'Unknown User';
                String? profileImageUrl = user['profileImageUrl'];
                String userId = filteredUsers[index].id;

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundImage:
                          profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : null,
                      child:
                          profileImageUrl == null
                              ? const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey,
                              )
                              : null,
                    ),
                    title: Text(
                      username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: FutureBuilder<bool>(
                      future: _isConnected(currentUser.uid, userId),
                      builder: (context, connectedSnapshot) {
                        if (connectedSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (connectedSnapshot.hasError) {
                          return const Icon(Icons.error, color: Colors.red);
                        }
                        bool isConnected = connectedSnapshot.data ?? false;

                        if (isConnected) {
                          return const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'Connected',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }

                        // Check if a request is pending
                        return FutureBuilder<bool>(
                          future: _isRequestPending(currentUser.uid, userId),
                          builder: (context, pendingSnapshot) {
                            if (pendingSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (pendingSnapshot.hasError) {
                              return const Icon(Icons.error, color: Colors.red);
                            }
                            bool isPending = pendingSnapshot.data ?? false;

                            if (isPending) {
                              return const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Pending',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            }

                            // Show the "add person" icon if not connected and no pending request
                            return IconButton(
                              icon: const Icon(
                                Icons.person_add,
                                color: Colors.green,
                              ),
                              onPressed:
                                  () => _sendConnectionRequest(
                                    currentUser.uid,
                                    userId,
                                  ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
