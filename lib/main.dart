import 'package:flutter/material.dart';
import './pages/home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '简单天气',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      themeMode: ThemeMode.light,
      home: Home(),
    );
  }
}
