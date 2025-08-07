import 'package:flutter/material.dart';
import 'package:personal_bahi_khata/data/file_handler.dart';
import 'package:personal_bahi_khata/data/statemanager.dart';

final expenseNotifier = ExpenseNotifier();

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Personal Bahi Khata',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FileHandler(),
    );
  }
}
