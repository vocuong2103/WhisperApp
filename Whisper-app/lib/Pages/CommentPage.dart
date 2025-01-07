import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/PostModel.dart';
import '../Services/api.dart';

class CommentPage extends StatefulWidget {
  final String postId;
  final ScrollController scrollController;

  CommentPage({required this.postId, required this.scrollController});

  @override
  _CommentPageState createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  List<Comments> _comments = [];
  bool _isLoading = true;
  String? _token;
  String? _userId;
  final Api api = Api();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
      _userId = prefs.getString('userId');
    });
    if (_token != null) {
      _fetchComments();
    }
  }

  Future<void> _fetchComments() async {
    final result = await api.getCommentsByPost(widget.postId, _token!);
    if (result['success']) {
      setState(() {
        _comments = (result['comments'] as List)
            .map((comment) => Comments.fromJson(comment))
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

  Future<void> _addComment() async {
    final content = _commentController.text;
    if (content.isNotEmpty) {
      final result = await api.addComment(widget.postId, content, _token!);
      if (result['success']) {
        _commentController.clear();
        _fetchComments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final result = await api.deleteComment(commentId, _token!);
    if (result['success']) {
      _fetchComments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bình luận',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _isLoading
              ? Expanded(child: Center(child: CircularProgressIndicator()))
              : _comments.isEmpty
                  ? Expanded(
                      child: Center(
                          child: Text('Không có bình luận nào',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey))))
                  : Expanded(
                      child: ListView.builder(
                        controller: widget.scrollController,
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  comment.user?.avatar ??
                                      'assets/default_avatar.jpg',
                                ),
                              ),
                              title: Text(comment.user?.name ?? 'Unknown',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(comment.content ?? '',
                                  style: TextStyle(color: Colors.black87)),
                              trailing: comment.user?.sId == _userId
                                  ? PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert),
                                      onSelected: (value) {
                                        if (value == 'delete') {
                                          _deleteComment(comment.sId!);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) {
                                        return [
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Xóa'),
                                          ),
                                        ];
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Thêm bình luận...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
