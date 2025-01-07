import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/api.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final Api api = Api();
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showAlert("Lỗi", "Mật khẩu mới và xác nhận mật khẩu không khớp", AlertType.error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      final result = await api.changePassword(
        token,
        _oldPasswordController.text,
        _newPasswordController.text,
        _confirmPasswordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        _showAlert("Thành công", "Đổi mật khẩu thành công", AlertType.success);
      } else {
        _showAlert("Lỗi", result['message'] ?? 'Đổi mật khẩu thất bại', AlertType.error);
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      _showAlert("Lỗi", "Token không khả dụng. Vui lòng đăng nhập lại.", AlertType.error);
    }
  }

  void _showAlert(String title, String desc, AlertType type) {
    Alert(
      context: context,
      type: type,
      title: title,
      desc: desc,
      style: AlertStyle(
        backgroundColor: Colors.white,
        alertBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        animationType: AnimationType.grow,
      ),
    ).show();

    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pop(true);
      if (type == AlertType.success) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đổi mật khẩu', style: TextStyle(color: Colors.amber)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.amber),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _oldPasswordController,
                labelText: 'Mật khẩu cũ',
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _newPasswordController,
                labelText: 'Mật khẩu mới',
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _confirmPasswordController,
                labelText: 'Xác nhận mật khẩu mới',
              ),
              SizedBox(height: 24),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.amber))
                  : ElevatedButton(
                      onPressed: _changePassword,
                      child: Text('Đổi mật khẩu', style: TextStyle(color: Colors.black, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                      ),
                    ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String labelText}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 4,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(Icons.lock, color: Colors.amber),
          labelStyle: TextStyle(color: Colors.amber),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        ),
        obscureText: true,
        style: TextStyle(color: Colors.amber),
      ),
    );
  }
}