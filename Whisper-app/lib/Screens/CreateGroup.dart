import 'package:chatapp/Screens/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatapp/Model/ChatModel.dart';
import 'package:chatapp/Services/api.dart';

class CreateGroup extends StatefulWidget {
  @override
  _CreateGroupState createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> selectedFriends = [];
  String? _token;
  String? _userId;
  final Api api = Api();
  final TextEditingController _groupNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTokenAndFriends();
  }

  Future<void> _loadTokenAndFriends() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
      _userId = prefs.getString('userId');
    });
    if (_token != null) {
      _fetchFriends();
    }
  }

  Future<void> _fetchFriends() async {
    final result = await api.getFriendsList(_token!);
    if (result['success']) {
      setState(() {
        friends = List<Map<String, dynamic>>.from(result['friends']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  void _toggleSelection(Map<String, dynamic> friend) {
    setState(() {
      if (selectedFriends.contains(friend)) {
        selectedFriends.remove(friend);
      } else {
        selectedFriends.add(friend);
      }
    });
  }

  Future<void> _createGroupChat() async {
    if (_groupNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập tên nhóm')),
      );
      return;
    }

    if (selectedFriends.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn ít nhất hai người bạn')),
      );
      return;
    }

    List<String> participantIds =
        selectedFriends.map((friend) => friend['_id'] as String).toList();
    participantIds.add(_userId!);

    final result = await api.createGroupChat(
      _userId!,
      participantIds,
      _groupNameController.text,
      _token!,
    );

    if (result['success']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            sourchat: Chat.fromJson(result['chat']),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Tạo Nhóm', style: TextStyle(color: Color(0xFFFFDD4D), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFFFFDD4D)), // Màu vàng cho nút callback
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _groupNameController,
              style: TextStyle(color: Color(0xFFFFDD4D)),
              decoration: InputDecoration(
                labelText: 'Tên Nhóm',
                labelStyle: TextStyle(color: Color(0xFFFFDD4D)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFDD4D)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFDD4D), width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Chọn Bạn Bè',
              style: TextStyle(
                color: Color(0xFFFFDD4D),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: friends.isEmpty
                  ? Center(
                      child: Text(
                        'Không có bạn bè nào',
                        style: TextStyle(color: Color(0xFFFFDD4D), fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        final isSelected = selectedFriends.contains(friend);
                        return Card(
                          color: Colors.grey[900],
                          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 30,
                              backgroundImage: friend['avatar'] != null
                                  ? NetworkImage(friend['avatar'])
                                  : AssetImage('assets/default_avatar.jpg') as ImageProvider,
                            ),
                            title: Text(
                              friend['name'] ?? 'Không rõ',
                              style: TextStyle(color: Color(0xFFFFDD4D), fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              friend['phoneNumber'] ?? 'Không rõ',
                              style: TextStyle(color: Colors.grey),
                            ),
                            trailing: Icon(
                              isSelected ? Icons.check_circle : Icons.check_circle_outline,
                              color: isSelected ? Color(0xFFFFDD4D) : Colors.grey,
                            ),
                            onTap: () => _toggleSelection(friend),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createGroupChat,
        child: Icon(Icons.arrow_forward, color: Colors.black),
        backgroundColor: Color(0xFFFFDD4D), // Màu vàng
      ),
    );
  }
}