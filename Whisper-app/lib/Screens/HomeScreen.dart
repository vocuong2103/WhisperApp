import 'package:chatapp/Model/ChatModel.dart';
import 'package:chatapp/Pages/FriendPage.dart';
import 'package:chatapp/Pages/PostPage.dart';
import 'package:chatapp/Screens/NotificationPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatapp/Screens/PersonalInfoPage.dart';
import 'package:chatapp/Pages/ChatPage.dart';
import 'package:chatapp/Services/api.dart';
import 'package:chatapp/Screens/IndividualPage.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key, required this.sourchat}) : super(key: key);
  final Chat sourchat;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Default to Chat page
  String? _token;
  final Api api = Api(); // Khởi tạo đối tượng Api

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
  }

  Future<int> _getFriendRequestCount() async {
    if (_token == null) {
      return 0;
    }
    final result = await api.getFriendRequests(_token!);
    if (result['success']) {
      return (result['friendRequests'] as List).length;
    } else {
      return 0;
    }
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PersonalInfo()),
      ).then((_) {
        // Khi trở lại trang HomeScreen, có thể cần làm mới dữ liệu hoặc kiểm tra trạng thái người dùng
        _loadToken();
      });
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user['avatar'] != null
            ? NetworkImage(user['avatar'])
            : AssetImage('assets/default_avatar.jpg') as ImageProvider,
        radius: 25,
      ),
      title: Text(
        user['name'] ?? 'Unknown',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        user['phoneNumber'] ?? 'Unknown',
        style: TextStyle(
          color: Colors.grey,
        ),
      ),
      onTap: () async {
        if (user['chat'] != null) {
          // Navigate to existing chat
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IndividualPage(
                  sId: user['chat']['_id'],
                  receiverName: user['name'],
                  chatType: user['chat']['type'],
                ),
            ),
          );
        } else {
          // Create a new chat
          final newChat = await api.createChat(
              widget.sourchat.userId!, user['_id'], _token!);
          if (newChat['success']) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IndividualPage(
                    sId: newChat['chat']['_id'],
                    receiverName: user['name'],
                    chatType: newChat['chat']['type'],
                  ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(newChat['message'])),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
      ChatPage(sourchat: widget.sourchat),
      PostPage(),
      FriendScreen(sourchat: widget.sourchat),
    ];

     return Scaffold(
      appBar: AppBar(
        title: Text(
          "Whisper",
          style: TextStyle(
            color: Color(0xFFFFDD4D),
            fontSize: 18,
          ),
        ),
        actions: [
          FutureBuilder<int>(
            future: _getFriendRequestCount(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return IconButton(
                  icon: Icon(Icons.notifications, color: Color(0xFFFFDD4D)), // Changed icon color to yellow
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotificationPage()),
                    );
                  },
                );
              } else {
                return Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications, color: Color(0xFFFFDD4D)), // Changed icon color to yellow
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NotificationPage()),
                        );
                      },
                    ),
                    if (snapshot.hasData && snapshot.data! > 0)
                      Positioned(
                        right: 11,
                        top: 11,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '${snapshot.data}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              }
            },
          ),
        ],
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: _selectedIndex == 3
                ? SizedBox.shrink() // Prevent rendering any content for the 'Calls' tab when it's not used
                : _pages[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.messenger,
                  color: _selectedIndex == 0 ? Color(0xFFFFDD4D) : Colors.grey),
              onPressed: () => _onItemTapped(0),
            ),
            IconButton(
              icon: Icon(Icons.public,
                  color: _selectedIndex == 1 ? Color(0xFFFFDD4D) : Colors.grey),
              onPressed: () => _onItemTapped(1),
            ),
            IconButton(
              icon: Icon(Icons.clear_all_rounded,
                  color: _selectedIndex == 2 ? Color(0xFFFFDD4D) : Colors.grey),
              onPressed: () => _onItemTapped(2),
            ),
            IconButton(
              icon: Icon(Icons.perm_contact_calendar_rounded,
                  color: _selectedIndex == 3 ? Color(0xFFFFDD4D) : Colors.grey),
              onPressed: () => _onItemTapped(3),
            ),
          ],
        ),
      ),
    );
  }
}