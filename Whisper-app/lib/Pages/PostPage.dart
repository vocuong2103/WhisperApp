import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/PostModel.dart';
import '../Services/api.dart';
import 'CommentPage.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:timeago/timeago.dart' as timeago_vi;

class PostPage extends StatefulWidget {
  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  List<Data> _posts = [];
  bool _isLoading = true;
  String? _token;
  String? _userId;
  final Api api = Api();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadToken();
    timeago.setLocaleMessages('vi', timeago_vi.ViMessages());
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
      _userId = prefs.getString(
          'userId'); // Assuming you store the avatar URL in SharedPreferences
    });
    if (_token != null) {
      _fetchPosts();
    }
  }

  Future<void> _fetchPosts() async {
    final result = await api.getPost(_token!);
    if (result['success']) {
      setState(() {
        _posts = (result['post']['data'] as List)
            .map((post) => Data.fromJson(post))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Future<void> _toggleLike(String postId) async {
    final result = await api.likePost(postId);
    if (result['success']) {
      _fetchPosts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Future<void> _createPost(String content) async {
    final result = await api.createPost(content, _token!);
    if (result['success']) {
      _fetchPosts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Future<void> _updatePost(String postId, String content) async {
    final result = await api.updatePost(postId, content, _token!);
    if (result['success']) {
      _fetchPosts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Future<void> _deletePost(String postId) async {
    final result = await api.deletePost(postId, _token!);
    if (result['success']) {
      _fetchPosts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  void _showUpdatePostDialog(String postId, String currentContent) {
    final TextEditingController _contentController =
        TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Cập nhật bài đăng'),
          content: TextField(
            controller: _contentController,
            decoration: InputDecoration(hintText: 'Nhập nội dung mới'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                _updatePost(postId, _contentController.text);
                Navigator.of(context).pop();
              },
              child: Text('Cập nhật'),
            ),
          ],
        );
      },
    );
  }

  String _getShortContent(String content) {
    if (content.length > 200) {
      return content.substring(0, 200) + '...';
    }
    return content;
  }

  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _showCommentBottomSheet(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return CommentPage(
              postId: postId,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Bài đăng'),
        backgroundColor: Colors.grey[200],
      ),
      backgroundColor: Colors.grey[200],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.newspaper,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _contentController,
                          decoration: InputDecoration(
                            hintText: 'Đăng suy nghĩ của bạn',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                        TextButton(
                        onPressed: () {
                          _createPost(_contentController.text);
                          _contentController.clear();
                        },
                        child: Icon(Icons.send, color: Colors.black,), // Changed text to send icon
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _posts.isEmpty
                      ? Center(child: Text('Không có bài đăng nào'))
                      : ListView.builder(
                          padding: EdgeInsets.all(10),
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            final post = _posts[index];
                            final bool isLiked =
                                post.likes?.contains(_userId) ?? false;
                            final String timeAgo = timeago.format(DateTime.parse(post.createdAt!), locale: 'vi');

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: Colors.black, width: 2),
                              ),
                              elevation: 10,
                              shadowColor: Color(0xFFB8860B),
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: NetworkImage(
                                              post.user?.avatar ??
                                                  'assets/default_avatar.jpg'),
                                          radius: 25,
                                        ),
                                        SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              post.user?.name ?? 'Unknown',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                            Text(
                                              timeAgo,
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Spacer(),
                                        if (post.user?.sId == _userId)
                                          PopupMenuButton<String>(
                                            icon: Icon(Icons.edit_note),
                                            onSelected: (value) {
                                              if (value == 'update') {
                                                _showUpdatePostDialog(post.sId!,
                                                    post.content ?? '');
                                              } else if (value == 'delete') {
                                                _deletePost(post.sId!);
                                              }
                                            },
                                            itemBuilder:
                                                (BuildContext context) {
                                              return [
                                                PopupMenuItem(
                                                  value: 'update',
                                                  child: Text('Cập nhật'),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Text('Xóa'),
                                                ),
                                              ];
                                            },
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      _isExpanded ? post.content ?? '' : _getShortContent(post.content ?? ''),
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    if (post.content != null && post.content!.length > 200)
                                      GestureDetector(
                                        onTap: _toggleExpanded,
                                        child: Text(
                                          _isExpanded ? 'Thu gọn' : 'Xem thêm',
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                      ),
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${post.likes?.length ?? 0} lượt thích'),
                                        Text('${post.comments?.length ?? 0} bình luận'),
                                      ],
                                    ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                isLiked
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: isLiked
                                                    ? Color(0xFFFFDD4D)
                                                    : Colors.grey,
                                              ),
                                              onPressed: () =>
                                                  _toggleLike(post.sId!),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.comment,
                                                  color: Colors.grey),
                                              onPressed: () {
                                                _showCommentBottomSheet(post.sId!);
                                              },
                                            ),
                                          ],
                                        ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}