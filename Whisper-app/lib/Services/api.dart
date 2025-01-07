import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  final String baseUrl =
      'http://10.21.14.129:5000/api'; // Thay thế bằng URL của API của bạn

  Api();

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String phoneNumber,
    String name, // Thêm trường name vào tham số
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'name': name, // Thêm trường name vào body
      }),
    );

    if (response.statusCode == 201) {
      return {'success': true, 'message': 'User registered successfully'};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Unknown error'
      };
    }
  }
  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Check for null values
        final token = responseData['token'] ?? '';
        final userId = responseData['user']?['id'] ?? '';

        if (token.isEmpty || userId.isEmpty) {
          print('Token or userId is empty');
          return {
            'success': false,
            'message': 'Unexpected response format',
          };
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userId', userId);

        return {
          'success': true,
          'message': responseData['message'] ?? 'Login successful',
          'token': token,
          'user': responseData['user'],
        };
      } else {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Unknown error';
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      print('API Error: $e');
      return {
        'success': false,
        'message': 'Failed to connect to the server',
      };
    }
  }
   // Đổi mật khẩu người dùng
  Future<Map<String, dynamic>> changePassword(
    String token,
    String oldPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/changePassword'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': 'Password changed successfully',
      };
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
      };
    }
  }
  // Logout
  Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/logout'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Xóa token từ SharedPreferences sau khi đăng xuất
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('userId');

        return {'success': true, 'message': 'Logout successful'};
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('API Error: $e');
      return {
        'success': false,
        'message': 'Failed to connect to the server',
      };
    }
  }

  // Tìm kiếm người dùng theo số điện thoại
  Future<Map<String, dynamic>> searchUserByPhoneNumber(
      String phoneNumber, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/search'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token', // Thêm token vào header để xác thực
        },
        body: jsonEncode(<String, String>{
          'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'],
          'user': responseData['user'], // Trả về thông tin người dùng
          'chat': responseData['chat'], // Trả về thông tin đoạn chat nếu có
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('API Error: $e');
      return {
        'success': false,
        'message': 'Failed to connect to the server',
      };
    }
  }

  // Tạo đoạn chat mới
  Future<Map<String, dynamic>> createChat(
      String userId, String targetUserId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats/create'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'userId': userId,
          'targetUserId': targetUserId,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'],
          'chat': responseData['chat'],
        };
      } else {
        return {
          'success': false,
          'message':
              jsonDecode(response.body)['message'] ?? 'Lỗi không xác định',
        };
      }
    } catch (e) {
      print('Lỗi API: $e');
      return {
        'success': false,
        'message': 'Kết nối tới máy chủ thất bại',
      };
    }
  }
  // createGroupChat
  Future<Map<String, dynamic>> createGroupChat(
      String userId, List<String> participantIds, String name, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats/createGroup'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, dynamic>{
          'userId': userId,
          'participantIds': participantIds,
          'name': name,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'],
          'chat': responseData['chat'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('API Error: $e');
      return {
        'success': false,
        'message': 'Failed to connect to the server',
      };
    }
  }
  // Lấy danh sách chat của người dùng
  Future<Map<String, dynamic>> getChatsByUser(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chats/getChatsByUser'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Sử dụng token để xác thực
      },
    );

    if (response.statusCode == 200) {
      print(jsonDecode(response.body)); // In ra dữ liệu trả về từ API
      return {'success': true, 'chats': jsonDecode(response.body)['chats']};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message']
      };
    }
  }
  //Xoá đoạn chat và các tin nhắn trong đoạn chat đó
  Future<Map<String, dynamic>> deleteChat(String chatId, String token) async {
  
  final response = await http.delete(
    Uri.parse('$baseUrl/chats/delete/$chatId'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token', // Thêm token vào header để xác thực
    },
  );

  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');
  
  if (response.statusCode == 200) {
    return {'success': true, 'message': 'Chat deleted successfully'};
  } else {
    return {
      'success': false,
      'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
    };
  }
}

  // Lấy hồ sơ người dùng hiện tại
  Future<Map<String, dynamic>> getCurrentUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Thêm token vào header để xác thực
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'profile': jsonDecode(response.body)['profile']};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message']
      };
    }
  }

  // Cập nhật hồ sơ người dùng
  Future<Map<String, dynamic>> updateUserProfile(
      String token, Map<String, dynamic> updatedProfile) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token', // Thêm token vào header để xác thực
      },
      body: jsonEncode(updatedProfile),
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': 'Profile updated successfully',
        'profile': jsonDecode(response.body)['profile']
      };
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message']
      };
    }
  }

  

  //Message Logic
  // Tạo tin nhắn mới
  Future<Map<String, dynamic>> createMessage({
    required String chatId,
    required String senderId,
    required String content,
    String type = 'text',
    String? fileUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'chatId': chatId,
        'senderId': senderId,
        'content': content,
        'type': type,
        'fileUrl': fileUrl,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
      };
    }
  }

  // Cập nhật tin nhắn mới nhất của chat
  Future<Map<String, dynamic>> updateLastMessage(
      String chatId, String messageId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chats/updateLastMessage'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'chatId': chatId,
        'messageId': messageId,
      }),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Last message updated successfully'};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message']
      };
    }
  }

  // Lấy tất cả tin nhắn trong một cuộc trò chuyện
  Future<Map<String, dynamic>> getMessagesByChat(String chatId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/$chatId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)['data']};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message']
      };
    }
  }

  // Cập nhật tin nhắn
  Future<Map<String, dynamic>> updateMessage(String messageId, String content,
      {String? type, String? fileUrl}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/messages/$messageId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'content': content,
        'type': type,
        'fileUrl': fileUrl,
      }),
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': jsonDecode(response.body)['message'],
        'data': jsonDecode(response.body)['data']
      };
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message']
      };
    }
  }

  // Xóa tin nhắn
  Future<Map<String, dynamic>> deleteMessage(String messageId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/messages/$messageId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Message deleted successfully'};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message']
      };
    }
  }

  // Đánh dấu tin nhắn là đã đọc
  Future<Map<String, dynamic>> markAsRead(
      String messageId, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/markAsRead/$messageId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Message marked as read'};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message']
      };
    }
  }

  //Gửi kết bạn
  Future<Map<String, dynamic>> sendFriendRequest(
      String recipientId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/send'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'recipientId': recipientId,
      }),
    );

    if (response.statusCode == 201) {
      return {'success': true, 'message': 'Friend request sent successfully'};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Unknown error'
      };
    }
  }

  // Chấp nhận yêu cầu kết bạn
  Future<Map<String, dynamic>> acceptFriendRequest(
      String requestId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/accept'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'requestId': requestId,
      }),
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': 'Friend request accepted successfully'
      };
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Unknown error'
      };
    }
  }

  // Từ chối lời mời kết bạn
  Future<Map<String, dynamic>> rejectFriendRequest(
      String requestId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friends/reject'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'requestId': requestId,
      }),
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': 'Friend request rejected successfully'
      };
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Unknown error'
      };
    }
  }

  // Lấy danh sách bạn bè
  Future<Map<String, dynamic>> getFriendsList(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'friends': jsonDecode(response.body)};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message']
      };
    }
  }

  // Xóa bạn bè
  Future<Map<String, dynamic>> removeFriend(
      String friendId, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/friends/remove'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'friendId': friendId,
      }),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Friend removed successfully'};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Unknown error'
      };
    }
  }

  // Kiểm tra tình trạng kết bạn
  Future<Map<String, dynamic>> checkFriendship(
      String userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends/checkfriends/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': jsonDecode(response.body)['message']};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message']
      };
    }
  }

  // Lấy danh sách lời mời kết bạn
  Future<Map<String, dynamic>> getFriendRequests(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/friends/friendRequest'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {
        'success': true,
        'friendRequests': jsonDecode(response.body),
      };
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
      };
    }
  }

  // Thêm thành viên vào nhóm
  Future<Map<String, dynamic>> addMemberToGroup(
      String chatId, String newMemberId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats/addMemberToGroup'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'chatId': chatId,
          'newMemberId': newMemberId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'],
          'chat': responseData['chat'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('API Error: $e');
      return {
        'success': false,
        'message': 'Failed to connect to the server',
      };
    }
  }

  // Xóa thành viên khỏi nhóm
  Future<Map<String, dynamic>> removeMemberFromGroup(
      String chatId, String memberId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats/removeMemberFromGroup'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'chatId': chatId,
          'memberId': memberId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'],
          'chat': responseData['chat'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('API Error: $e');
      return {
        'success': false,
        'message': 'Failed to connect to the server',
      };
    }
  }

  // Đổi tên nhóm
  Future<Map<String, dynamic>> renameGroup(
      String chatId, String newName, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats/renameGroup'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(<String, String>{
          'chatId': chatId,
          'newName': newName,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'],
          'chat': responseData['chat'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('API Error: $e');
      return {
        'success': false,
        'message': 'Failed to connect to the server',
      };
    }
  }
//Thêm bài đăng
  Future<Map<String, dynamic>> createPost(String content, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'content': content,
      }),
    );

    if (response.statusCode == 201) {
      return {'success': true, 'post': jsonDecode(response.body)};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
      };
    }
  }
//Lấy bài đăng
  Future<Map<String, dynamic>> getPost(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/posts'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'post': jsonDecode(response.body)};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
      };
    }
  }
//like/Unlike bài đăng
  Future<Map<String, dynamic>> likePost(String postId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      return {
        'success': false,
        'message': 'User not authenticated',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/like'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('API Error: $e');
      return {
        'success': false,
        'message': 'Failed to connect to the server',
      };
    }
  }
//Cập nhật bài đăng
  Future<Map<String, dynamic>> updatePost(
      String postId, String content, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'content': content,
      }),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'post': jsonDecode(response.body)};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
      };
    }
  }
//Xoá bài đăng
  Future<Map<String, dynamic>> deletePost(String postId, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/posts/$postId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Post deleted successfully'};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
      };
    }
  }

  //Thêm bình luận
  Future<Map<String, dynamic>> addComment(
      String postId, String content, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/posts/$postId/comments'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'postId': postId,
        'content': content,
      }),
    );

    if (response.statusCode == 201) {
      return {'success': true, 'comment': jsonDecode(response.body)};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
      };
    }
  }
//Lấy bình luận
    Future<Map<String, dynamic>> getCommentsByPost(String postId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token', // Thêm token vào header để xác thực
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'comments': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      print('API Error: $e');
      return {
        'success': false,
        'message': 'Failed to connect to the server',
      };
    }
  }
 //Xoá bình luận
  Future<Map<String, dynamic>> deleteComment(
      String commentId, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/comments/$commentId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Comment deleted successfully'};
    } else {
      return {
        'success': false,
        'message': jsonDecode(response.body)['message'] ?? 'Unknown error',
      };
    }
  }

}
