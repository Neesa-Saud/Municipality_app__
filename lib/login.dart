import 'package:flutter/material.dart';
import '../function/auth_function.dart';
import '../function/database_function.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final _formkey = GlobalKey<FormState>();
  bool isLogin = false; // Initially false, so it starts on signup screen
  String username = '';
  String email = '';
  String password = '';

  final DatabaseService _databaseService = DatabaseService();

  Future<void> _signIn() async {
    String? result = await signin(email, password);
    if (result == null) {
      if (email == 'admin@gmail.com' && password == 'admin123') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/user');
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $result')));
    }
  }

  Future<void> _signUp() async {
    String? authResult = await signup(email, password);
    if (authResult == null) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? dbResult = await _databaseService.saveUserData(username, email);
        if (dbResult == null) {
          Navigator.pushReplacementNamed(context, '/user');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save user data: $dbResult')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signup failed: $authResult')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background red semi-circle
            Positioned(
              bottom: -screenHeight * 0.65, // Position to cover bottom half
              left: -screenWidth * 0.1, // Center horizontally
              child: Container(
                height: screenHeight * 1.3, // Large enough to cover bottom
                width: screenWidth * 2, // Wide enough to cover screen width
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
            ),
            // Main content
            Column(
              children: [
                // Logo and Welcome Text (Top Section)
                SizedBox(height: screenHeight * 0.05), // Responsive top padding
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: screenWidth * 0.15, // Responsive logo size
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/Bhimdatt_Logo-.png',
                            fit: BoxFit.cover,
                            width: screenWidth * 0.3,
                            height: screenWidth * 0.3,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      const Text(
                        'WELCOME',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'सबैको समस्या , साझा अधिकार',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                // Form Section
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        width: screenWidth * 0.52, // 80% of screen width
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.01,
                        ),
                        child: Form(
                          key: _formkey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isLogin)
                                TextFormField(
                                  key: const ValueKey('username'),
                                  decoration: const InputDecoration(
                                    hintText: "Enter Username",
                                    hintStyle: TextStyle(color: Colors.grey),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  validator: (value) {
                                    if (value!.length < 3) {
                                      return 'Username is too small';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    setState(() {
                                      username = value!;
                                    });
                                  },
                                ),
                              SizedBox(height: screenHeight * 0.02),
                              TextFormField(
                                key: const ValueKey('email'),
                                decoration: const InputDecoration(
                                  hintText: "Enter your email",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  if (!value!.contains('@')) {
                                    return 'Invalid email';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  setState(() {
                                    email = value!;
                                  });
                                },
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              TextFormField(
                                obscureText: true,
                                key: const ValueKey('password'),
                                decoration: const InputDecoration(
                                  hintText: "Enter Password",
                                  hintStyle: TextStyle(color: Colors.grey),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (value) {
                                  if (value!.length < 6) {
                                    return 'Password is too small';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  setState(() {
                                    password = value!;
                                  });
                                },
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Container(
                                width: double.infinity,
                                height: screenHeight * 0.07,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_formkey.currentState!.validate()) {
                                      _formkey.currentState!.save();
                                      if (isLogin) {
                                        _signIn();
                                      } else {
                                        _signUp();
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: Text(
                                    isLogin ? 'Login' : 'Signup',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    isLogin = !isLogin;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                                child:
                                    isLogin
                                        ? const Text(
                                          "Don't have an account? Signup",
                                        )
                                        : const Text(
                                          "Already Signed Up? Login",
                                        ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
