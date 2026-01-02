import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wordpractice_admin/courses_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAQpxacnlMcxw7fWkSNr7fXAsTSwtcK91w",
      authDomain: "manara-41e79.firebaseapp.com",
      projectId: "manara-41e79",
      storageBucket: "manara-41e79.firebasestorage.app",
      messagingSenderId: "712994301412",
      appId: "1:712994301412:web:ec52e84c9624b28c2393f1",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CoursesScreen(),
    );
  }
}
