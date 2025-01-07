import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatapp/Services/api.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _friendRequests = [];
  String? _token;
  final Api api = Api();

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
    if (_token != null) {
      _fetchFriendRequests();
    }
  }

  Future<void> _fetchFriendRequests() async {
    final result = await api.getFriendRequests(_token!);
    if (result['success']) {
      setState(() {
        _friendRequests = List<Map<String, dynamic>>.from(result['friendRequests'] as List);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

Future<void> _acceptFriendRequest(String requestId) async {
  final result = await api.acceptFriendRequest(requestId, _token!);
  if (result['success']) {
    _fetchFriendRequests();
    _showAlertDialog('Bạn đã chấp nhận lời mời kết bạn', Icons.check_circle);
  } else {
    _showAlertDialog(result['message'], Icons.error);
  }
}

Future<void> _rejectFriendRequest(String requestId) async {
  final result = await api.rejectFriendRequest(requestId, _token!);
  if (result['success']) {
    _fetchFriendRequests();
    _showAlertDialog('Bạn đã từ chối lời mời kết bạn', Icons.cancel);
  } else {
    _showAlertDialog(result['message'], Icons.error);
  }
}

void _showAlertDialog(String message, IconData icon) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      Future.delayed(Duration(seconds: 3), () {
        Navigator.of(context).pop(true);
      });
      return AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: Colors.blue),
            SizedBox(width: 10),
            Text('Thông báo'),
          ],
        ),
        content: Text(message),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lời mời kết bạn',
       style: TextStyle(color: Color(0xFFFFDD4D)),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFFFDD4D)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: Colors.grey[200],
      body: _friendRequests.isEmpty
          ? Center(child: Text('Không có lời mời kết bạn'))
          : ListView.builder(
              itemCount: _friendRequests.length,
              itemBuilder: (context, index) {
                final request = _friendRequests[index];
                final requester = request['requester'];
                final requestDate = request['createdAt'] != null
                    ? DateTime.parse(request['createdAt'])
                    : null;
                final now = DateTime.now();
                final difference = requestDate != null
                    ? now.difference(requestDate)
                    : null;
                final timeAgoText = difference != null
                    ? (difference.inDays > 0
                        ? '${difference.inDays} ngày trước'
                        : difference.inHours > 0
                        ? '${difference.inHours} giờ trước'
                        : '${difference.inMinutes} pht trước')
                    : 'Ngày không xác định';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: requester['avatar'] != null
                                ? NetworkImage(requester['avatar'])
                                : AssetImage('assets/default_avatar.jpg') as ImageProvider,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  requester['name'] ?? 'Không xác định',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  timeAgoText,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => _acceptFriendRequest(request['_id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFFDD4D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Icon(Icons.check, color: Colors.black),
                          ),
                          SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _rejectFriendRequest(request['_id']),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.black,
                              side: BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}