import 'package:flutter/material.dart';

/// 我还没有正式把它用在项目中，这个示例有一点点麻烦，日后再做
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Curd'),
        ),
      ),
    );
  }
}