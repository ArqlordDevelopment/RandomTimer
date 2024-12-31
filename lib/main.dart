import 'package:flutter/material.dart';
import 'screen/RandomAlarmScreen.dart';
import 'screen/RandomTimerScreen.dart';

void main() {
  runApp(RandomAlarmTimerApp());
}

class RandomAlarmTimerApp extends StatelessWidget {
  const RandomAlarmTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: Colors.white, fontSize: 24),
          bodyMedium: TextStyle(color: Colors.white, fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white10,
          labelStyle: TextStyle(color: Colors.white),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30.0)),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF353535), // Onyx
                  Color(0xFF555555), // Dark Gray
                  Color(0xFF353535), // Steel Gray
                ],
              ),
            ),
          ),
          // Tab Navigation and Content
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.black.withOpacity(0.8),
              title: const Text(
                'Random Alarm & Timer',
                style: TextStyle(
                  color: Colors.white, // White header font
                ),
              ),
              bottom: const TabBar(
                indicatorColor: Colors.white, // White underline for active tab
                labelColor: Colors.white, // White text for selected tab
                unselectedLabelColor: Colors.white70, // Slightly dimmed text for unselected tabs
                tabs: [
                  Tab(text: "Random Alarm"),
                  Tab(text: "Random Timer"),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                RandomAlarmScreen(),
                RandomTimerScreen(),]
            ),
          ),
        ],
      ),
    );
  }
}

