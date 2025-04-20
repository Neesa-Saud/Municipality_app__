import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For formatting timestamps

class NoticePage extends StatelessWidget {
  const NoticePage({super.key});

  // Function to add a connection between two users
  Future<void> _addConnection(String userId1, String userId2) async {
    // Add connection for user1 (current user) to user2
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId1)
        .collection('connections')
        .doc(userId2)
        .set({
          'connectedUserId': userId2,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // Add connection for user2 (sender) to user1
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId2)
        .collection('connections')
        .doc(userId1)
        .set({
          'connectedUserId': userId1,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  // Function to handle accepting a connection request
  Future<void> _acceptConnectionRequest(
    String currentUserId,
    String fromUserId,
    String notificationId,
  ) async {
    try {
      // Add the connection for both users
      await _addConnection(currentUserId, fromUserId);

      // Update the notification status to 'accepted'
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .doc(notificationId)
          .update({'status': 'accepted'});

      ScaffoldMessenger.of(
        navigatorKey.currentContext!,
      ).showSnackBar(const SnackBar(content: Text('Connection accepted')));
    } catch (e) {
      ScaffoldMessenger.of(
        navigatorKey.currentContext!,
      ).showSnackBar(SnackBar(content: Text('Error accepting connection: $e')));
    }
  }

  // Function to handle rejecting a connection request
  Future<void> _rejectConnectionRequest(
    String currentUserId,
    String notificationId,
  ) async {
    try {
      // Update the notification status to 'rejected'
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .doc(notificationId)
          .update({'status': 'rejected'});

      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Connection request rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        navigatorKey.currentContext!,
      ).showSnackBar(SnackBar(content: Text('Error rejecting connection: $e')));
    }
  }

  // Function to delete a notification
  Future<void> _deleteNotification(
    String currentUserId,
    String notificationId,
    BuildContext context,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }

  // Function to format timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, yyyy hh:mm a').format(dateTime);
  }

  // GlobalKey to access ScaffoldMessenger from a StatelessWidget
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        toolbarHeight: 70,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No notifications'));
            }

            final notifications = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                var notification =
                    notifications[index].data() as Map<String, dynamic>;
                String notificationId = notifications[index].id;
                String type = notification['type'];

                if (type == 'connection_request') {
                  // Handle connection request notifications
                  String fromUsername =
                      notification['fromUsername'] ?? 'Unknown User';
                  String fromUserId = notification['fromUserId'];
                  String status = notification['status'] ?? 'pending';

                  if (status != 'pending') return const SizedBox.shrink();

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        '$fromUsername wants to connect with you',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Received on: ${_formatTimestamp(notification['timestamp'])}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed:
                                () => _acceptConnectionRequest(
                                  currentUser.uid,
                                  fromUserId,
                                  notificationId,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed:
                                () => _rejectConnectionRequest(
                                  currentUser.uid,
                                  notificationId,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              bool? confirmDelete = await showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Delete Notification'),
                                      content: const Text(
                                        'Are you sure you want to delete this notification?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );

                              if (confirmDelete == true) {
                                await _deleteNotification(
                                  currentUser.uid,
                                  notificationId,
                                  context,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (type == 'problem_status_update') {
                  // Handle problem status update notifications
                  String problemTitle =
                      notification['problemTitle'] ?? 'Unknown Problem';
                  String status = notification['status'] ?? 'unknown';

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        'Problem "$problemTitle" status updated to $status',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Updated on: ${_formatTimestamp(notification['timestamp'])}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          bool? confirmDelete = await showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Delete Notification'),
                                  content: const Text(
                                    'Are you sure you want to delete this notification?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                          );

                          if (confirmDelete == true) {
                            await _deleteNotification(
                              currentUser.uid,
                              notificationId,
                              context,
                            );
                          }
                        },
                      ),
                    ),
                  );
                }

                return const SizedBox.shrink(); // For unknown notification types
              },
            );
          },
        ),
      ),
    );
  }
}
