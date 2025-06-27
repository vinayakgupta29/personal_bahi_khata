import 'package:flutter/material.dart';
import 'package:personal_bahi_khata/data/statemanager.dart';
import 'package:personal_bahi_khata/presentation/homepage.dart';

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
      home: HomePage(),
    );
  }
}

// Window 559bd66187d0 -> Android Emulator - Pixel_8_Pro_API_35:5554:
//         mapped: 1
//         hidden: 0
//         at: 12,65
//         size: 1342,691
//         workspace: 2 (2)
//         floating: 0
//         pseudo: 0
//         monitor: 0
//         class: Emulator
//         title: Android Emulator - Pixel_8_Pro_API_35:5554
//         initialClass: Emulator
//         initialTitle: Emulator
//         pid: 28471
//         xwayland: 1
//         pinned: 0
//         fullscreen: 0
//         fullscreenClient: 0
//         grouped: 0
//         tags: 
//         swallowing: 0
//         focusHistoryID: 1
//         inhibitingIdle: 0
//         xdgTag: 
//         xdgDescription: 