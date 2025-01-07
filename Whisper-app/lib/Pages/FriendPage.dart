import 'package:chatapp/Model/ChatModel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatapp/Services/api.dart';
import 'package:chatapp/Screens/IndividualPage.dart';
import 'package:chatapp/Screens/CreateGroup.dart';

class FriendScreen extends StatefulWidget {
  FriendScreen({Key? key, required this.sourchat}) : super(key: key);
  final Chat sourchat;

  @override
  _FriendScreenState createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  List<Map<String, dynamic>> _friends = [];
  String? _token;
  final Api api = Api();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  String? _userId;

  Future<void> _loadToken() async {
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
        _friends = List<Map<String, dynamic>>.from(result['friends']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Future<void> _removeFriend(String friendId) async {
    final result = await api.removeFriend(friendId, _token!);
    if (result['success']) {
      setState(() {
        _friends.removeWhere((friend) => friend['_id'] == friendId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa bạn bè thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(String friendId) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa bạn bè này không?'),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Xóa', style: TextStyle(color: Color(0xFFFFDD4D))),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToChat(Map<String, dynamic> friend) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID is not available')),
      );
      return;
    }

    final chatResult = await api.createChat(_userId!, friend['_id'], _token!);
    if (chatResult['success']) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IndividualPage(
            sId: chatResult['chat']['_id'],
            receiverName: friend['name'],
            chatType: chatResult['chat']['type'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(chatResult['message'])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Bạn bè', style: TextStyle(color: Color(0xFFFFDD4D), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.black,
        child: _friends.isEmpty
            ? Center(
                child: Text(
                  'Không có bạn bè',
                  style: TextStyle(color: Color(0xFFFFDD4D), fontSize: 18),
                ),
              )
            : ListView.builder(
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final friend = _friends[index];
                  return Dismissible(
                    key: Key(friend['_id']),
                    background: Container(
                      color: Colors.red,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Icon(Icons.delete, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      final shouldDelete = await _showDeleteConfirmationDialog(friend['_id']);
                      if (shouldDelete == true) {
                        await _removeFriend(friend['_id']);
                        return true;
                      } else {
                        return false;
                      }
                    },
                    child: Card(
                      color: Colors.grey[900],
                      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: friend['avatar'] != null
                                  ? NetworkImage(friend['avatar'])
                                  : AssetImage('assets/default_avatar.jpg') as ImageProvider,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: friend['status'] == 'online' ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          friend['name'] ?? 'Unknown',
                          style: TextStyle(color: Color(0xFFFFDD4D), fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          friend['phoneNumber'] ?? 'Unknown',
                          style: TextStyle(color: Colors.grey),
                        ),
                        onTap: () => _navigateToChat(friend),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateGroup()),
          );
        },
        backgroundColor: Color(0xFFFFDD4D),
        child: Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
