import 'package:chatapp/Screens/IndividualPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/ChatModel.dart';
import '../Services/api.dart';
import 'dart:math';

class ChatPage extends StatefulWidget {
  final Chat sourchat;

  ChatPage({Key? key, required this.sourchat}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Chats> chatModels = [];
  bool _isLoading = true;
  String? _errorMessage;
  late Api _api;
  late String currentUserId;
  Map<String, String> nicknames = {};
  bool _isSearching = false;
  final TextEditingController _phoneNumberController = TextEditingController();
  final Api api = Api();
  String? _token;
  Map<String, dynamic>? _searchedUser;

  @override
  void initState() {
    super.initState();
    _initializeApi();
    _fetchChats();
    _loadNicknames();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
  }

  Future<void> _searchUserByPhoneNumber(String phoneNumber) async {
    if (_token == null) {
      return;
    }

    final result = await api.searchUserByPhoneNumber(phoneNumber, _token!);

    setState(() {
      if (result['success']) {
        _searchedUser = result['user'];
        _searchedUser!['chat'] = result['chat'];
        _showSearchResultDialog(_searchedUser!);
      } else {
        _searchedUser = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    });
  }

  void _showSearchResultDialog(Map<String, dynamic> user) async {
    bool isFriend = false;
    if (_token != null) {
      final friendshipStatus = await api.checkFriendship(user['_id'], _token!);
      if (friendshipStatus['success']) {
        isFriend = friendshipStatus['message'] == 'Users are friends.';
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: Container(
            height: 300,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundImage: user['avatar'] != null
                            ? NetworkImage(user['avatar'])
                            : AssetImage('assets/default_avatar.jpg')
                                as ImageProvider,
                        radius: 50,
                      ),
                      SizedBox(height: 10),
                      Text(
                        user['name'] ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: Icon(Icons.message, color: Colors.black),
                            onPressed: () async {
                              Navigator.of(context).pop();
                              if (user['chat'] != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => IndividualPage(
                                      sId: user['chat']['_id'],
                                      receiverName: user['name'],
                                      chatType: 'private',
                                    ),
                                  ),
                                );
                              } else {
                                final newChat = await api.createChat(
                                    widget.sourchat.userId!,
                                    user['_id'],
                                    _token!);
                                if (newChat['success']) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => IndividualPage(
                                        sId: newChat['chat']['_id'],
                                        receiverName: user['name'],
                                        chatType: 'private',
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
                          ),
                          if (!isFriend)
                            IconButton(
                              icon: Icon(Icons.person_add, color: Colors.black),
                              onPressed: () async {
                                final friendRequest = await api
                                    .sendFriendRequest(user['_id'], _token!);
                                if (friendRequest['success']) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Đã gửi kết bạn')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text(friendRequest['message'])),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _initializeApi() async {
    _api = Api();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('userId') ?? 'defaultUserId';
  }

  Future<void> _fetchChats() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Token is not available. Please login again.';
        });
        return;
      }

      final result = await _api.getChatsByUser(token);

      if (result['success']) {
        final List<dynamic> data = result['chats'];
        setState(() {
          chatModels = data
              .map((chat) => Chats.fromJson(chat as Map<String, dynamic>))
              .toList();
          chatModels.sort((a, b) {
            DateTime aTime = DateTime.parse(a.lastMessage?.createdAt ?? '1970-01-01T00:00:00Z');
            DateTime bTime = DateTime.parse(b.lastMessage?.createdAt ?? '1970-01-01T00:00:00Z');
            return bTime.compareTo(aTime);
          });
          _isLoading = false;
          _loadNicknames();
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load chats: ${result['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $e';
      });
    }
  }

  Future<void> _loadNicknames() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (var chat in chatModels) {
      final nickname = prefs.getString('nickname_${chat.sId}');
      if (nickname != null) {
        setState(() {
          nicknames[chat.sId!] = nickname;
        });
      }
    }
  }

  Future<void> _deleteChat(String chatId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      final result = await _api.deleteChat(chatId, token);

      if (result['success']) {
        setState(() {
          chatModels.removeWhere((chat) => chat.sId == chatId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa đoạn chat')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete chat: ${result['message']}')),
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmationDialog(String chatId) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xoá đoạn chat này không?'),
          actions: <Widget>[
            TextButton(
              child: Text('Huỷ'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Xoá'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  String _formatMessageTime(String createdAt) {
    try {
      if (createdAt == 'Unknown') {
        return '-:-';
      }
      final DateTime dateTime = DateTime.parse(createdAt);
      final localDateTime = dateTime.toLocal();
      final now = DateTime.now();

      if (localDateTime.year == now.year &&
          localDateTime.month == now.month &&
          localDateTime.day == now.day) {
        return DateFormat('HH:mm').format(localDateTime);
      } else {
        return DateFormat('dd/MM').format(localDateTime);
      }
    } catch (e) {
      return '-:-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _isSearching
            ? TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                ),
                style: TextStyle(color: Colors.black),
                autofocus: true,
                keyboardType: TextInputType.phone,
                onSubmitted: (value) {
                  _searchUserByPhoneNumber(value);
                  setState(() {
                    _isSearching = false;
                  });
                },
              )
            : Text('Đoạn chat', style: TextStyle(color: Color(0xFFFFDD4D), fontWeight: FontWeight.bold)  ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Color(0xFFFFDD4D)),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _phoneNumberController.clear();
                }
              });
            },
          ),
        ],
        backgroundColor: Colors.black,
      ),
      body: Container(
        color: Colors.black,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFFFFDD4D)))
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: TextStyle(color: Color(0xFFFFDD4D))))
                : ListView.builder(
                    itemCount: chatModels.length,
                    itemBuilder: (context, index) {
                      final chat = chatModels[index];
                      final lastMessage = chat.lastMessage;
                      final lastMessageContent = lastMessage?.content ?? 'Không có tin nhắn';
                      final lastTimeMessage = lastMessage?.createdAt ?? 'Unknown';
                      String formattedTime = _formatMessageTime(lastTimeMessage);

                      final receiver = chat.participants?.firstWhere(
                        (participant) => participant.sId != currentUserId,
                        orElse: () => Participants(name: 'Người lạ', avatar: null, status: 'offline'),
                      );
                      final receiverName = receiver?.name ?? 'Người lạ';
                      final receiverAvatar = receiver?.avatar;
                      final receiverStatus = receiver?.status ?? 'offline';

                      final nickname = nicknames[chat.sId] ?? receiverName;

                      final isSentByCurrentUser = lastMessage?.sender == currentUserId;
                      final displayMessageContent = isSentByCurrentUser
                          ? 'Bạn: ${lastMessageContent.length > 20 ? lastMessageContent.substring(0, 20) + '...' : lastMessageContent}'
                          : lastMessageContent.length > 20 ? lastMessageContent.substring(0, 20) + '...' : lastMessageContent;

                      List<Widget> avatarWidgets = [];
                      if (chat.type == 'group' && chat.participants != null) {
                        final random = Random();
                        final participants = chat.participants!;
                        final avatars = participants.where((p) => p.avatar != null).map((p) => p.avatar!).toList();
                        avatars.shuffle(random);
                        final selectedAvatars = avatars.take(3).toList();

                        for (var avatar in selectedAvatars) {
                          avatarWidgets.add(
                            Positioned(
                              child: CircleAvatar(
                                backgroundImage: NetworkImage(avatar),
                                radius: 10,
                              ),
                            ),
                          );
                        }
                      }

                      final displayName = chat.type == 'group' ? chat.name ?? 'Group' : nickname;

                      return Dismissible(
                        key: Key(chat.sId ?? ''),
                        background: Container(
                          color: Colors.red,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          final shouldDelete = await _showDeleteConfirmationDialog(chat.sId ?? '');
                          if (shouldDelete == true) {
                            await _deleteChat(chat.sId ?? '');
                            return true;
                          } else {
                            return false;
                          }
                        },
                        child: Column(
                          children: [
                            ListTile(
                              leading: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    backgroundImage: receiverAvatar != null
                                        ? NetworkImage(receiverAvatar)
                                        : AssetImage('assets/default_avatar.jpg') as ImageProvider,
                                    radius: 25,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: receiverStatus == 'online' ? Colors.green : Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFFFFDD4D),
                                ),
                              ),
                              subtitle: Text(displayMessageContent, style: TextStyle(color: Colors.white70)),
                              trailing: Text(formattedTime, style: TextStyle(color: Colors.white70)),
                              onTap: () async {
                                if (chat.sId != null) {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => IndividualPage(
                                        sId: chat.sId!,
                                        receiverName: displayName,
                                        chatType: chat.type!,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _fetchChats();
                                  }
                                }
                              },
                            ),
                            if (index < chatModels.length - 1)
                              Divider(height: 1, color: Colors.grey[800]),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
