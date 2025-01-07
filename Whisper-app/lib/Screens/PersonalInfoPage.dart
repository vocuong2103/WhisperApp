import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/UserModel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Pages/EditProfilePage.dart';
import 'LoginScreen.dart';
import '../Services/api.dart'; // Nhập đối tượng Api
import '../Screens/ChangePasswordPage.dart'; // Thêm import này

// Định nghĩa URL cơ sở cho API
const String baseUrl = 'http://10.21.14.129:5000/api';

class PersonalInfo extends StatefulWidget {
  @override
  _PersonalInfoState createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfo> {
  User? _user;
  bool _isLoading = true;
  final Api api = Api(); // Khởi tạo đối tượng Api

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    String? token = await _getToken();
    if (token != null) {
      final result = await getCurrentUserProfile(token);
      if (result['success']) {
        setState(() {
          _user = User.fromJson(result['profile']);
          _isLoading = false;
        });
      } else {
        _showErrorSnackbar(
            result['message'] ?? 'Không thể tải thông tin người dùng');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      _showErrorSnackbar('Token không khả dụng. Vui lòng đăng nhập lại.');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> getCurrentUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Thêm token vào header để xác thực
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'profile': jsonDecode(response.body)};
    } else {
      final responseBody = jsonDecode(response.body);
      return {'success': false, 'message': responseBody['message']};
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signOut() async {
    String? token = await _getToken();
    if (token != null) {
      final result =
          await api.logout(token); // Sử dụng phương thức logout từ api.dart
      if (result['success']) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('userId');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  LoginScreen()), // Điều hướng đến trang đăng nhập
          (route) =>
              false, // Xóa tất cả các trang trước đó khỏi lịch sử điều hướng
        );
      } else {
        _showErrorSnackbar(result['message'] ?? 'Đăng xuất không thành công');
      }
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hồ sơ', style: TextStyle(color: Color(0xFFFFDD4D))),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFFFDD4D)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(child: Text('Không thể tải thông tin người dùng.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(_user!.avatar),
                            backgroundColor: Colors.black,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.black,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditProfilePage(user: _user!),
                                    ),
                                  );
                                },
                                child:
                                    Icon(Icons.edit, color: Color(0xFFFFDD4D)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _user!.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 4.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: Icon(Icons.security, color: Colors.black),
                          title: Text('Bảo mật'),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                            );
                          },
                        ),
                      ),
                      Card(
                        elevation: 4.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading:
                              Icon(Icons.notifications, color: Colors.black),
                          title: Text('Thông báo'),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Handle Notifications tap
                          },
                        ),
                      ),
                      Card(
                        elevation: 4.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: Icon(Icons.settings, color: Colors.black),
                          title: Text('Cài đặt'),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Handle Settings tap
                          },
                        ),
                      ),
                      Card(
                        elevation: 4.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: Icon(Icons.help, color: Colors.black),
                          title: Text('Trung tâm trợ giúp'),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Handle Help Center tap
                          },
                        ),
                      ),
                      Card(
                        elevation: 4.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: Icon(Icons.logout, color: Colors.black),
                          title: Text('Đăng xuất'),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: _signOut,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}