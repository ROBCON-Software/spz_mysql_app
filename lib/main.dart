import 'package:flutter/material.dart';
import 'screens/pin_entry_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SPZ App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        hintColor: const Color(0x88004B81),
        cardTheme: CardThemeData(  // Changed from CardTheme to CardThemeData
          color: Colors.lightBlue[50],
        ),
      ),
      home: const PinEntryScreen(),
    );
  }
}