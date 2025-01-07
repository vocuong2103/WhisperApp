class Chat {
  String? userId;
  List<Chats>? chats;

  Chat({this.userId, this.chats});

  Chat.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    if (json['chats'] != null) {
      chats = [];
      json['chats'].forEach((v) {
        chats!.add(Chats.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userId'] = this.userId;
    if (this.chats != null) {
      data['chats'] = this.chats!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Chats {
  String? sId;
  List<Participants>? participants;
  String? type;
  String? name;
  String? createdAt;
  String? updatedAt;
  int? iV;
  LastMessage? lastMessage;
  

  Chats({
    this.sId,
    this.participants,
    this.type,
    this.name,
    this.createdAt,
    this.updatedAt,
    this.iV,
    this.lastMessage,
  });

  Chats.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    if (json['participants'] != null) {
      participants = [];
      json['participants'].forEach((v) {
        participants!.add(Participants.fromJson(v));
      });
    }
    type = json['type'];
    name = json['name'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
    lastMessage = json['lastMessage'] != null
        ? LastMessage.fromJson(json['lastMessage'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = this.sId;
    if (this.participants != null) {
      data['participants'] = this.participants!.map((v) => v.toJson()).toList();
    }
    data['type'] = this.type;
    data['name'] = this.name;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    if (this.lastMessage != null) {
      data['lastMessage'] = this.lastMessage!.toJson();
    }
    return data;
  }
}

class Participants {
  String? sId;
  String? name;
  String? avatar;
  String? status;

  Participants({this.sId, this.name, this.avatar, this.status});

  Participants.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    avatar = json['avatar'];
    status = json['status']; 

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['avatar'] = this.avatar;
    data['status'] = this.status;
    return data;
  }
}

class LastMessage {
  String? sId;
  String? chat;
  String? sender;
  String? content;
  String? type;
  String? fileUrl;
  List<dynamic>? readBy;
  String? createdAt;
  String? updatedAt;
  int? iV;

  LastMessage({
    this.sId,
    this.chat,
    this.sender,
    this.content,
    this.type,
    this.fileUrl,
    this.readBy,
    this.createdAt,
    this.updatedAt,
    this.iV,
  });

  LastMessage.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    chat = json['chat'];
    sender = json['sender'];
    content = json['content'];
    type = json['type'];
    fileUrl = json['fileUrl'];
    readBy = json['readBy'] != null ? List<dynamic>.from(json['readBy']) : null;
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = this.sId;
    data['chat'] = this.chat;
    data['sender'] = this.sender;
    data['content'] = this.content;
    data['type'] = this.type;
    data['fileUrl'] = this.fileUrl;
    data['readBy'] = this.readBy;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}