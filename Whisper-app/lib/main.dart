import 'package:chatapp/Model/ChatModel.dart';
import 'package:chatapp/Screens/HomeScreen.dart';
import 'package:chatapp/Screens/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/Screens/LoadingScreen.dart';



void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }
  Future<void> _loadResources() async {
    // Giả lập việc tải tài nguyên
    await Future.delayed(Duration(seconds: 3));
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _isLoading ? LoadingScreen() : LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(
              sourchat: Chat(
                chats: [],
              ),
            ),
      },
    );
  }
}