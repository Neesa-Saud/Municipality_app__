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
              bottom: -screenHeight * 0.65,
              left: -screenWidth * 0.1,
              child: Container(
                height: screenHeight * 1.3,
                width: screenWidth * 2,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent,
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            // Main content
            Column(
              children: [
                SizedBox(height: screenHeight * 0.05),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: screenWidth * 0.15,
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
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Text(
                        'सबैको समस्या , साझा अधिकार',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        width: screenWidth * 0.8,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                          vertical: screenHeight * 0.02,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formkey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isLogin)
                                TextFormField(
                                  key: const ValueKey('username'),
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    labelStyle: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value!.length < 3) {
                                      return 'Username is too short';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    setState(() {
                                      username = value!;
                                    });
                                  },
                                ),
                              if (!isLogin)
                                SizedBox(height: screenHeight * 0.02),
                              TextFormField(
                                key: const ValueKey('email'),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: const TextStyle(
                                    color: Colors.black87,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (!value!.contains('@')) {
                                    return 'Enter a valid email address';
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
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: const TextStyle(
                                    color: Colors.black87,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                validator: (value) {
                                  if (value!.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  setState(() {
                                    password = value!;
                                  });
                                },
                              ),
                              SizedBox(height: screenHeight * 0.04),
                              SizedBox(
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
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 6,
                                    shadowColor: Colors.redAccent,
                                  ),
                                  child: Text(
                                    isLogin ? 'Login' : 'Sign Up',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
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
                                  foregroundColor: Colors.black,
                                  textStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child:
                                    isLogin
                                        ? const Text(
                                          "Don't have an account? Sign Up",
                                        )
                                        : const Text(
                                          "Already have an account? Login",
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
