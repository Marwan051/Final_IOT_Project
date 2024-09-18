import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_client/screens/home_screen.dart';
import 'package:flutter_client/screens/login_screen.dart';
import 'package:flutter_client/screens/reading_screen.dart';
import 'package:flutter_client/screens/signup_screen.dart';
import 'package:flutter_client/screens/writing_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        "/login": (context) => const LoginScreen(),
        "/signup": (context) => const SignupScreen(),
        "/home": (context) => const HomeScreen(),
        "/reading": (context) => const ReadingScreen(),
        "/writing": (context) => const WritingScreen(),
      },
      title: 'Firebase App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}
