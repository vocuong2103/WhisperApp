import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/Model/MessageModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatapp/Services/api.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../Pages/CameraPage.dart'; // Import CameraPage

class IndividualPage extends StatefulWidget {
  final String sId;
  final String receiverName;
  final String chatType; // Add chatType

  IndividualPage({required this.sId, required this.receiverName, required this.chatType}); // Add chatType

  @override
  _IndividualPageState createState() => _IndividualPageState();
}

class _IndividualPageState extends State<IndividualPage> {
  String _nickname = '';

  late Api _api;
  List<Data> messages = [];
  bool isLoading = true;
  late SharedPreferences prefs;
  late String currentUserId;
  bool showEmojiPicker = false;
  TextEditingController _controller = TextEditingController();
  ScrollController _scrollController = ScrollController();
  late IO.Socket socket;
  bool isCameraOpen = false;
  String _backgroundImage =
      'assets/background/chatbg.jpg'; // Default background image
  String _selectedBackground = 'assets/background/chatbg.jpg';
List<Data> searchResults = [];

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    // Initialize SocketService and Api
    socket = IO.io('http://10.21.14.129:5000',
        IO.OptionBuilder().setTransports(['websocket']).build());

    _api = Api();

    // Connect to socket
    socket.connect();
    // Join chat on socket connection
    socket.on('connect', (_) {
      print('Connected to WebSocket');
      socket.emit('joinChat', widget.sId);
    });
    // Listen for new messages
    socket.on('message', (data) {
      if (data is Map<String, dynamic>) {
        // Ensure data is in correct format
        if (data['chatId'] == widget.sId) {
          print('Received message: ${data['content']}');
          print('Avatar received URL: ${data['avatar']}'); // Console log avatar URL
          if (mounted) {
            // Check if the widget is still in the widget tree
            setState(() {
              // Manually create Data object to ensure correct parsing
              final newMessage = Data(
                sId: data['_id'],
                chat: data['chatId'],
                sender: Sender( 
                  sId: data['senderId'],
                  avatar: data['avatar'],
                ),
                content: data['content'],
                type: data['type'],
                fileUrl: data['fileUrl'],
                createdAt: data['createdAt'],
                updatedAt: data['updatedAt'],
              );
              messages.add(newMessage);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            });
          }
        }
      } else {
        print('Received data is not in expected format');
      }
    });
    _fetchMessages(); // Fetch messages from server or local storage
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('userId') ?? "defaultUserId";
    String backgroundImage =
        prefs.getString('background') ?? 'assets/background/chatbg.jpg';
    String nickname = prefs.getString('nickname_${widget.sId}') ?? '';

    setState(() {
      _backgroundImage = backgroundImage;
      _nickname = nickname;
      _selectedBackground = backgroundImage;
    });

    _fetchMessages();
  }

  void _showNicknameDialog() {
    TextEditingController nicknameController =
        TextEditingController(text: _nickname);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Đặt biệt hiệu'),
          content: TextField(
            controller: nicknameController,
            decoration: InputDecoration(hintText: 'Nhập biệt hiệu mới'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _nickname = nicknameController.text;
                });
                await prefs.setString('nickname_${widget.sId}', _nickname);
                Navigator.pop(context);
              },
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveNicknameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xóa biệt hiệu'),
          content: Text(
              'Bạn có chắc chắn muốn xóa biệt hiệu và quay lại tên gốc không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Notify ChatPage to refresh
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _nickname =
                      widget.receiverName; // Revert to the original name
                });
                await prefs.remove('nickname_${widget.sId}');
                Navigator.pop(context);
              },
              child: Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchMessages() async {
    try {
      final result = await _api.getMessagesByChat(widget.sId);
      setState(() {
        isLoading = false;
        if (result['success']) {
          messages = (result['data'] as List)
              .map((item) => Data.fromJson(item))
              .toList();
          // Scroll to the bottom after data is loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        } else {
          _showError(result['message']);
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('An error occurred while fetching messages.');
    }
  }

  void _searchMessages(String query) {
  setState(() {
    searchResults = messages
        .where((message) =>
            message.content != null &&
            message.content!.toLowerCase().contains(query.toLowerCase()))
        .toList();
  });
}

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      // If no client, try again after a short delay
      Future.delayed(Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _sendMessage(String messageContent) async {
    if (messageContent.isEmpty) return;
    final createdAt = DateTime.now().toIso8601String();

    setState(() {
      isLoading = true;
    });

    try {
      final response = await _api.createMessage(
        chatId: widget.sId,
        senderId: currentUserId,
        content: messageContent,
        type: 'text',
        fileUrl: null,
      );

      if (response['success']) {
        final messageData = response['data'];

        setState(() {
          messages.add(
            Data(
              sId: messageData['_id'],
              chat: messageData['chat'],
              sender: Sender(
                  sId: messageData['sender']['_id'],
                  avatar: messageData['sender']['avatar']),
              content: messageData['content'],
              type: messageData['type'],
              fileUrl: messageData['fileUrl'],
              createdAt: createdAt,
              updatedAt: messageData['updatedAt'],
            ),
          );
          _controller.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
          print('Sent message: $messageContent'); // Debug message
          print(
              'Sender avatar: ${messageData['sender']['avatar']}'); // Console log avatar
        });

        // Print the sender avatar URL before emitting the socket event
        print(
            'Emitting newMessage with avatar URL: ${messageData['sender']['avatar']}');

        socket.emit('newMessage', {
          'chatId': widget.sId,
          'senderId': currentUserId,
          'avatar': messageData['sender']['avatar'],
          'content': messageContent,
          'createdAt': createdAt,
          'type': 'text',
          'fileUrl': null,
        });
      } else {
        _showError(response['message']);
      }
    } catch (e) {
      _showError('An error occurred while sending the message.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _openCameraPage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero, // Remove dialog padding
          child: Stack(
            children: [
              CameraPage(
                onClose: () {
                  Navigator.pop(context); // Close dialog when user clicks "X"
                  setState(() {
                    isCameraOpen = false;
                  });
                },
              ),
              Positioned(
                top: 20, // Adjust top distance if needed
                right: 20, // Adjust right distance if needed
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog when user clicks "X"
                    setState(() {
                      isCameraOpen = false;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    setState(() {
      isCameraOpen = true;
    });
  }

  void _showChangeBackgroundDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thay đổi ảnh nền'),
          contentPadding: EdgeInsets.all(16.0),
          backgroundColor: Colors.grey[300],
          content: SizedBox(
            width: double.maxFinite,
            height: 280, // Adjust the height as needed
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBackgroundOption(
                      'assets/background/chatbg.jpg', 'Mc định'),
                  _buildBackgroundOption(
                      'assets/background/chatbg2.jpg', 'Khoa học'),
                  _buildBackgroundOption(
                      'assets/background/chatbg3.jpg', 'Màu sắc'),
                  _buildBackgroundOption(
                      'assets/background/chatbg4.jpg', 'Hình khối'),
                  _buildBackgroundOption(
                      'assets/background/chatbg5.jpg', 'Rạp phim'),
                  _buildBackgroundOption(
                      'assets/background/chatbg6.jpg', 'Bản vẽ'),
                  _buildBackgroundOption(
                      'assets/background/chatbg7.jpg', 'Vân gỗ'),
                  _buildBackgroundOption(
                      'assets/background/chatbg8.jpg', 'Bản đồ'),
                  _buildBackgroundOption(
                      'assets/background/chatbg9.jpg', 'Truyện tranh'),
                  _buildBackgroundOption(
                      'assets/background/chatbg10.jpg', 'Thành phố'),
                  // Add more options here if needed
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackgroundOption(String assetPath, String label) {
    // Determine if the current option is the selected one
    bool isSelected = assetPath == _selectedBackground;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          if (isSelected) Icon(Icons.check, color: Colors.green),
        ],
      ),
      onTap: () {
        setState(() {
          _selectedBackground = assetPath; // Update the selected background
        });
        _updateBackground(assetPath);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _updateBackground(String assetPath) async {
    setState(() {
      _backgroundImage = assetPath;
    });
    await prefs.setString('background', assetPath); // Save the new background
  }

  void _showAddMemberDialog() async {
    final friends = await _fetchFriends();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thêm thành viên vào nhóm'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: friends.length,
              itemBuilder: (BuildContext context, int index) {
                final friend = friends[index];
                return ListTile(
                  title: Text(friend['name']),
                  onTap: () async {
                    _addMemberToGroup(friend['_id']);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchFriends() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      final result = await Api().getFriendsList(token);
      if (result['success']) {
        return List<Map<String, dynamic>>.from(result['friends']);
      }
    }
    return [];
  }

  void _addMemberToGroup(String newMemberId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      final result = await Api().addMemberToGroup(widget.sId, newMemberId, token);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thêm thành viên thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thêm thành viên thất bại')),
        );
      }
    }
  }

  void _showRemoveMemberDialog() {
    final members = _getGroupMembersFromMessages();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xóa thành viên khỏi nhóm'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: members.length,
              itemBuilder: (BuildContext context, int index) {
                final member = members[index];
                return ListTile(
                  title: Text(member['name']),
                  onTap: () {
                    _removeMemberFromGroup(member['id']);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _getGroupMembersFromMessages() {
    final members = <Map<String, dynamic>>[];
    for (var message in messages) {
      if (message.sender != null && !members.any((m) => m['id'] == message.sender!.sId)) {
        members.add({
          'id': message.sender!.sId,
          'name': message.sender!.name ?? 'Unknown',
        });
      }
    }
    return members;
  }

  void _removeMemberFromGroup(String memberId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      final result = await Api().removeMemberFromGroup(widget.sId, memberId, token);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa thành viên thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa thành viên thất bại')),
        );
      }
    }
  }

  void _showRenameGroupDialog() {
    TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Đổi tên nhóm'),
          content: TextField(
            controller: _controller,
            decoration: InputDecoration(hintText: "Nhập tên nhóm mới"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () async {
                String newGroupName = _controller.text;
                if (newGroupName.isNotEmpty) {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  String? token = prefs.getString('token');
                  if (token != null) {
                    final result = await Api().renameGroup(widget.sId, newGroupName, token);
                    if (result['success']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đổi tên nhóm thành công')),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đổi tên nhóm thất bại')),
                      );
                    }
                  }
                }
              },
              child: Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  String _formatMessageTime(String createdAt) {
    try {
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
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_nickname.isEmpty ? widget.receiverName : _nickname),
        backgroundColor: Color(0xFFFFDD4D),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
        actions: [
          IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            showSearch(
              context: context,
              delegate: MessageSearchDelegate(
                messages: messages,
                onMessageSelected: (message) {
                  int index = messages.indexOf(message);
                  if (index != -1) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent * (index / messages.length),
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            );
          },
        ),
          PopupMenuButton<String>(
            onSelected: (String result) {
              switch (result) {
                case 'nickname':
                  _showNicknameDialog();
                  break;
                case 'remove_nickname':
                  _showRemoveNicknameDialog();
                  break;
                case 'background':
                  _showChangeBackgroundDialog();
                  break;
                case 'add_member':
                  _showAddMemberDialog();
                  break;
                case 'remove_member':
                  _showRemoveMemberDialog();
                  break;
                case 'rename_group':
                  _showRenameGroupDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              List<PopupMenuEntry<String>> menuItems = [
                if (widget.chatType != 'group') ...[
                  const PopupMenuItem<String>(
                    value: 'nickname',
                    child: Text('Đặt biệt hiệu'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'remove_nickname',
                    child: Text('Xóa biệt hiệu'),
                  ),
                ],
                const PopupMenuItem<String>(
                  value: 'background',
                  child: Text('Đổi nền'),
                ),
              ];

              if (widget.chatType == 'group') {
                menuItems.addAll([
                  const PopupMenuItem<String>(
                    value: 'add_member',
                    child: Text('Thêm vào nhóm'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'remove_member',
                    child: Text('Xóa khỏi nhóm'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'rename_group',
                    child: Text('Đổi tên nhóm'),
                  ),
                ]);
              }

              return menuItems;
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? Center(child: Text('Không có tin nhắn.'))
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isSentByCurrentUser =
                                message.sender?.sId == currentUserId;
                            final formattedTime = _formatMessageTime(message.createdAt ?? '');

                            return Align(
                              alignment: isSentByCurrentUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Row(
                                mainAxisAlignment: isSentByCurrentUser
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (!isSentByCurrentUser)
                                    CircleAvatar(
                                      backgroundImage: message.sender?.avatar != null && message.sender!.avatar!.isNotEmpty
                                          ? NetworkImage(message.sender!.avatar!)
                                          : AssetImage('assets/default_avatar.png') as ImageProvider,
                                    ),
                                  SizedBox(width: 10),
                                  Container(
                                    margin: EdgeInsets.symmetric(vertical: 5),
                                    child: IntrinsicWidth(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.75,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isSentByCurrentUser
                                                ? Colors.black
                                                : Color(0xFFFFDD4D),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                isSentByCurrentUser
                                                    ? CrossAxisAlignment.end
                                                    : CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                message.content ?? 'No content',
                                                style: TextStyle(
                                                  color: isSentByCurrentUser
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                formattedTime,
                                                style: TextStyle(
                                                  color: isSentByCurrentUser
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isSentByCurrentUser) SizedBox(width: 10),
                                  if (isSentByCurrentUser)
                                    CircleAvatar(
                                      backgroundImage: message.sender?.avatar != null && message.sender!.avatar!.isNotEmpty
                                          ? NetworkImage(message.sender!.avatar!)
                                          : AssetImage('assets/default_avatar.png') as ImageProvider,
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            if (showEmojiPicker) _buildEmojiPicker(),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      color: Color(0xFFFFDD4D),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  showEmojiPicker
                      ? Icons.keyboard
                      : Icons.emoji_emotions_outlined,
                  color: Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    showEmojiPicker = !showEmojiPicker;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.black),
                onPressed: _openCameraPage, // Open CameraPage
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Soạn tin nhắn',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 20.0),
                    ),
                    onTap: () {
                      setState(() {
                        showEmojiPicker = false;
                      });
                    },
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Colors.black),
                onPressed: () {
                  _sendMessage(_controller.text);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return EmojiPicker(
      onEmojiSelected: (category, emoji) {
        setState(() {
          _controller.text += emoji.emoji;
        });
      },
    );
  }
}
  class MessageSearchDelegate extends SearchDelegate<Data> {
  final List<Data> messages;
  final Function(Data) onMessageSelected;

  MessageSearchDelegate({required this.messages, required this.onMessageSelected});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, Data());
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = messages
        .where((message) =>
            message.content != null &&
            message.content!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final message = results[index];
        return ListTile(
          title: Text(message.content ?? 'No content'),
          onTap: () {
            onMessageSelected(message);
            close(context, message);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = messages
        .where((message) =>
            message.content != null &&
            message.content!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final message = suggestions[index];
        return ListTile(
          title: Text(message.content ?? 'No content'),
          onTap: () {
            query = message.content ?? '';
            showResults(context);
          },
        );
      },
    );
  }
}