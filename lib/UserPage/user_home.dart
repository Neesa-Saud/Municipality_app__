import 'package:flutter/material.dart';
import 'package:myapp/UserPage/Drawer/delete_profile.dart';
import 'package:myapp/UserPage/Drawer/profile.dart';
import 'package:myapp/UserPage/notice.dart';
import 'package:myapp/UserPage/report_problempage.dart';
import '../function/database_function.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final DatabaseService _databaseService = DatabaseService();
  int _selectedIndex = 0;
  String? _profileImageUrl;

  final List<Widget> _pages = [
    Container(), // Placeholder for Home page content
    NoticePage(), // Notice page
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    try {
      String imageUrl = userDoc.get('profileImageUrl');
      setState(() {
        _profileImageUrl = imageUrl;
      });
    } catch (e) {
      // field doesn't exist, set to null
      setState(() {
        _profileImageUrl = null;
      });
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, yyyy hh:mm a').format(dateTime);
  }

  Widget _buildHomeContent() {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                  child:
                      _profileImageUrl == null
                          ? const Icon(
                            Icons.person,
                            size: 20,
                            color: Colors.grey,
                          )
                          : null,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: FutureBuilder<String?>(
          future: _databaseService.getUsername(user!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                'Welcome...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text(
                'Welcome User',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              );
            }
            final username = snapshot.data ?? 'User';
            return Text(
              'Welcome $username',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            );
          },
        ),
        backgroundColor: Colors.redAccent.shade700,
        toolbarHeight: 90,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.redAccent.shade700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                    child:
                        _profileImageUrl == null
                            ? const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.grey,
                            )
                            : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.email ?? 'User',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                ).then((_) => _loadProfileImage()); // refresh image
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete Account'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DeleteProfilePage()),
                );
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Feed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
            const Divider(thickness: 1),
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
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No problems posted yet.'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var problem = snapshot.data!.docs[index];
                      String userId = problem['userId'];

                      return FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            );
                          }

                          String username = 'Unknown User';
                          String? userImageUrl;
                          if (userSnapshot.hasData &&
                              userSnapshot.data!.exists) {
                            final data =
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            username = data['username'] ?? 'Unknown User';
                            try {
                              userImageUrl = data['profileImageUrl'];
                            } catch (e) {
                              userImageUrl = null;
                            }
                          }

                          final String? imageUrl = problem['imageUrl'];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.grey,
                                        backgroundImage:
                                            userImageUrl != null
                                                ? NetworkImage(userImageUrl)
                                                : null,
                                        child:
                                            userImageUrl == null
                                                ? const Icon(
                                                  Icons.person,
                                                  size: 20,
                                                  color: Colors.white,
                                                )
                                                : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    problem['title'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    problem['description'],
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  if (imageUrl != null &&
                                      imageUrl.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 180,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: Text(
                                      _formatTimestamp(problem['timestamp']),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
      body: SafeArea(
        child:
            _selectedIndex == 0 ? _buildHomeContent() : _pages[_selectedIndex],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportProblemPage()),
          );
          setState(() {}); // Refresh feed after returning
        },
        backgroundColor: Colors.redAccent.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  Icons.home,
                  color:
                      _selectedIndex == 0
                          ? Colors.redAccent.shade700
                          : Colors.black54,
                ),
                onPressed: () => _onTabSelected(0),
                tooltip: 'Home',
              ),
              const SizedBox(width: 40),
              IconButton(
                icon: Icon(
                  Icons.notifications_active,
                  color:
                      _selectedIndex == 1
                          ? Colors.redAccent.shade700
                          : Colors.black54,
                ),
                onPressed: () => _onTabSelected(1),
                tooltip: 'Notice',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
