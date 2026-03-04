import 'package:flutter/material.dart';
import 'package:wordpractice_admin/features/courses/view/courses_screen.dart';

/// Root application widget.
/// Builds MaterialApp shell and sets initial route.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CoursesScreen(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
    );
  }
}

