import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatapp/Model/ChatModel.dart';
import 'package:chatapp/Screens/HomeScreen.dart';
import 'package:chatapp/Screens/RegisterScreen.dart';
import 'package:chatapp/Services/api.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Uri _youtubeUrl =
      Uri.parse('https://www.youtube.com/watch?v=mvbWdTGUg_U');
  bool _isLoading = false;

  late Api _api;

  @override
  void initState() {
    super.initState();
    _api = Api();
  }

  Future<void> _launchURL() async {
    if (!await launchUrl(_youtubeUrl)) {
      throw 'Không thể chạy $_youtubeUrl';
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _api.login(
        _emailController.text,
        _passwordController.text,
      );

      if (result['success']) {
        final String token = result['token'];
        final Map<String, dynamic> user = result['user'];
        final String userId = user['id'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userId', userId);

        print('Token saved: $token');
        print('User ID saved: $userId');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              sourchat: Chat(
                chats: [],
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFFFFDD4D)],
            stops: [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 300,
                      height: 300,
                    ),
                    Card(
                      color: const Color.fromARGB(255, 223, 220, 220),
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 120,
                              child: Row(
                                children: [
                                  Icon(Icons.mail),
                                  SizedBox(width: 10),
                                  Text(
                                    'Email',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: 'abc@gmail.com',
                                  border: InputBorder.none,
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      color: const Color.fromARGB(255, 223, 220, 220),
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 120,
                              child: Row(
                                children: [
                                  Icon(Icons.key),
                                  SizedBox(width: 10),
                                  Text(
                                    'Mật khẩu',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  hintText: '********',
                                  border: InputBorder.none,
                                  fillColor: Colors.white,
                                  filled: true,
                                ),
                                obscureText: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.black,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                        const Text("Chưa có tài khoản?"),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Đăng ký ngay!',
                            style: TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.black,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Color(0xFFFFDD4D),
                              backgroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 100, vertical: 20),
                              textStyle: TextStyle(fontSize: 18),
                            ),
                            child: Text("Đăng nhập"),
                          ),
                    SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom > 0
                            ? 20
                            : 50),
                    InkWell(
                      onTap: _launchURL,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.youtube_searched_for,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Hướng dẫn sử dụng',
                            style: TextStyle(
                              color: Color(0xFF8E6CEE),
                              fontSize: 15,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}