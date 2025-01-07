import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket _socket;
  Function? onMessageReceived;

  void initializeSocket() {
    _socket = IO.io('http://10.21.14.129:5000', IO.OptionBuilder()
        .setTransports(['websocket']) // for Flutter or Dart VM
        .build());

    _socket.onConnect((_) {
      print('Connected to socket server');
    });

    _socket.on('message', (data) {
      if (onMessageReceived != null) {
        onMessageReceived!(data);
      }
    });

    _socket.onDisconnect((_) {
      print('Disconnected from socket server');
    });
  }

  void sendMessage(String chatId, String senderId, String content, String type, String fileUrl) {
    _socket.emit('newMessage', {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'fileUrl': fileUrl,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
