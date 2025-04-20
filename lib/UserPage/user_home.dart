import 'package:flutter/material.dart';
import 'package:myapp/UserPage/Drawer/profile.dart';
import 'package:myapp/UserPage/community.dart';
import 'package:myapp/UserPage/contact.dart';
import 'package:myapp/UserPage/notice.dart';
import 'package:myapp/UserPage/report_problempage.dart';
import '../function/database_function.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final DatabaseService _databaseService = DatabaseService();
  int _selectedIndex = 0;
  String? _profileImageUrl; // To store the user's profile image URL

  final List<Widget> _otherPages = [
    CommunityPage(),
    NoticePage(),
    ContactPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage(); // Load the user's profile image on init
  }

  // Load the user's profile image from Firestore
  Future<void> _loadProfileImage() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userDoc.exists) {
        setState(() {
          _profileImageUrl = userDoc['profileImageUrl'];
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserHome()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMM d, yyyy hh:mm a').format(dateTime);
  }

  Widget _buildHomeContent() {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          _profileImageUrl != null
                              ? CachedNetworkImageProvider(_profileImageUrl!)
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
                    // Show the "Add" icon only when there is no profile image
                    if (_profileImageUrl == null)
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfilePage(),
                                ),
                              ).then((_) => _loadProfileImage());
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.4),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
            String username = snapshot.data ?? 'User';
            return Text(
              'Welcome $username',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            );
          },
        ),
        backgroundColor: Colors.red,
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          const SizedBox(width: 10),
        ],
        toolbarHeight: 100,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.red),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            _profileImageUrl != null
                                ? CachedNetworkImageProvider(_profileImageUrl!)
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
                      // Show the "Add" icon only when there is no profile image
                      if (_profileImageUrl == null)
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfilePage(),
                                  ),
                                ).then((_) => _loadProfileImage());
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.4),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.email ?? 'User',
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
                ).then((_) => _loadProfileImage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.sunny),
              title: const Text('Theme'),
              onTap: () {
                Navigator.pop(context);
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Adjust padding and image size based on screen width
          double padding = constraints.maxWidth > 600 ? 32.0 : 16.0;
          double imageHeight = constraints.maxWidth > 600 ? 300.0 : 150.0;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportProblemPage(),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  child: const Text('Post the problem'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(30, 50),
                  ),
                ),
                const SizedBox(height: 5),
                const Divider(),
                const Text(
                  'Feed',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Divider(),
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
                        return const Center(
                          child: Text('No problems posted yet.'),
                        );
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
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                );
                              }

                              String username = 'Unknown User';
                              String? userAvatarUrl;
                              if (userSnapshot.hasData &&
                                  userSnapshot.data!.exists) {
                                username =
                                    userSnapshot.data!['username'] ??
                                    'Unknown User';
                                userAvatarUrl =
                                    userSnapshot.data!['profileImageUrl'];
                              }

                              return Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundImage:
                                                    userAvatarUrl != null
                                                        ? CachedNetworkImageProvider(
                                                          userAvatarUrl,
                                                        )
                                                        : null,
                                                child:
                                                    userAvatarUrl == null
                                                        ? const Icon(
                                                          Icons.person,
                                                          size: 20,
                                                          color: Colors.grey,
                                                        )
                                                        : null,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  username,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            problem['title'],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            problem['description'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (problem['imageUrl'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 12.0,
                                              ),
                                              child: CachedNetworkImage(
                                                imageUrl: problem['imageUrl'],
                                                height: imageHeight,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                placeholder:
                                                    (
                                                      context,
                                                      url,
                                                    ) => const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        const Text(
                                                          'Error loading image',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Text(
                                        _formatTimestamp(problem['timestamp']),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
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
          );
        },
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
            _selectedIndex == 0
                ? _buildHomeContent()
                : _otherPages[_selectedIndex - 1],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_3_outlined),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            label: 'Notice',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Contact'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}
