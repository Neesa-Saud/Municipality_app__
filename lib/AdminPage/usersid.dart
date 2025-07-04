import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> _allUsers = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      setState(() {
        _allUsers =
            usersSnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredUsers() {
    if (_searchQuery.isEmpty) return _allUsers;
    final query = _searchQuery.toLowerCase();
    final matchingUsers =
        _allUsers
            .where(
              (user) => (user['username'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query),
            )
            .toList();

    final nonMatchingUsers =
        _allUsers
            .where(
              (user) =>
                  !(user['username'] ?? '').toString().toLowerCase().contains(
                    query,
                  ),
            )
            .toList();

    return [...matchingUsers, ...nonMatchingUsers];
  }

  void _showSearchDialog() {
    final TextEditingController searchController = TextEditingController(
      text: _searchQuery,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Search User'),
            content: TextField(
              controller: searchController,
              decoration: const InputDecoration(hintText: 'Enter username'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = searchController.text.trim();
                  });
                  Navigator.pop(context);
                },
                child: const Text('Search'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Users',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        toolbarHeight: 80,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Search User',
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? const Center(child: Text('No users found.'))
                : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    var user = filteredUsers[index];
                    String username = user['username'] ?? 'Unknown User';
                    String email = user['email'] ?? 'No Email';
                    String role = user['role'] ?? 'user';
                    String? profileImageUrl = user['profileImageUrl'];

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage:
                              profileImageUrl != null
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                          child:
                              profileImageUrl == null
                                  ? const Icon(
                                    Icons.person,
                                    size: 28,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                        title: Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Email: $email',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        trailing:
                            role == 'admin'
                                ? const Icon(
                                  Icons.admin_panel_settings,
                                  color: Colors.red,
                                  size: 28,
                                )
                                : null,
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
