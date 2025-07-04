import 'package:flutter/material.dart';
import 'package:myapp/AdminPage/admin_home.dart';
import 'package:myapp/UserPage/user_home.dart';
import 'package:myapp/login.dart'; // Your LogInPage
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
 
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.light),
      initialRoute: '/login', // Set initial route
      routes: {
        '/login': (context) => LogInPage(),
        '/admin': (context) => AdminHome(),
        '/user': (context) => UserHome(),
      },
    );
  }
}
