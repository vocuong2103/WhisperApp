import 'package:chatapp/Screens/CameraScreen.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatelessWidget {
  final VoidCallback onClose;

  const CameraPage({Key? key, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraScreen(), // Toàn bộ không gian camera
          Positioned(
            top: 20, // Điều chỉnh vị trí của nút đóng nếu cần
            right: 20,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: onClose,
            ),
          ),
        ],
      ),
    );
  }
}
