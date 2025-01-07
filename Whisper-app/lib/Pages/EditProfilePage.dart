import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/UserModel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EditProfilePage extends StatefulWidget {
  final User user;
  EditProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _avatarController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _avatarController = TextEditingController(text: widget.user.avatar);
  }

  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<bool> updateUserProfile(String token, User user) async {
    final response = await http.put(
      Uri.parse('http://10.21.14.129:5000/api/users/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print('Failed to update profile: ${response.body}');
      return false;
    }
  }

  void _saveProfile() async {
    String? token = await _getToken();
    if (token != null) {
      User updatedUser = User(
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        avatar: _avatarController.text,
        name: _nameController.text,
        status: widget.user.status,
        lastSeen: widget.user.lastSeen,
        createdAt: widget.user.createdAt,
        updatedAt: DateTime.now(),
        password: '',
      );

      bool success = await updateUserProfile(token, updatedUser);
      if (success) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            Future.delayed(Duration(seconds: 5), () {
              Navigator.of(context).pop(true);
              Navigator.of(context).pop(updatedUser);
            });
            return AlertDialog(
              title: Row(
                children: [
                  SizedBox(width: 10),
                  Text('Thông báo'),
                ],
              ),
              content: Container(
                height: MediaQuery.of(context).size.height *0.1,
                child: Row(
                  children: [
                    Text('Chỉnh sửa hồ sơ thành công'),
                    SizedBox(width: 10),
                    Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            Future.delayed(Duration(seconds: 5), () {
              Navigator.of(context).pop(true);
            });
            return AlertDialog(
              title: Row(
                children: [
                  SizedBox(width: 10),
                  Text('Thông báo'),
                ],
              ),
              content: Container(
                width: MediaQuery.of(context).size.width *
                    0.8, // Adjust the width as needed
                child: Row(
                  children: [
                    Text('Cập nhật hồ sơ thất bại'),
                    SizedBox(width: 10),
                    Icon(Icons.error, color: Colors.red),
                  ],
                ),
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chỉnh sửa hồ sơ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Thêm SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(widget.user.avatar),
              child: Align(
                alignment: Alignment.bottomRight,
                child: CircleAvatar(
                  backgroundColor: Colors.yellow,
                  radius: 15,
                  child: Icon(
                    Icons.camera_alt,
                    size: 15,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            _buildTextField('Họ và tên', _nameController, Icons.person),
            SizedBox(height: 16),
            _buildTextField('E-Mail', _emailController, Icons.email),
            SizedBox(height: 16),
            _buildTextField('Số điện thoại', _phoneController, Icons.phone),
            SizedBox(height: 16),
            _buildTextField('Ảnh đại diện', _avatarController, Icons.image),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.yellow,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text('Chỉnh sửa hồ sơ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}