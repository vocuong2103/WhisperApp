class MessageModel {
  bool? success;
  List<Data>? data;

  MessageModel({this.success, this.data});

  MessageModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? sId;
  String? chat;
  Sender? sender;
  String? content;
  String? type;
  String? fileUrl;
  List<dynamic>? readBy;
  String? createdAt;
  String? updatedAt;
  int? iV;

  Data(
      {this.sId,
      this.chat,
      this.sender,
      this.content,
      this.type,
      this.fileUrl,
      this.readBy,
      this.createdAt,
      this.updatedAt,
      this.iV});

  Data.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    chat = json['chat'];
    sender =
        json['sender'] != null ? new Sender.fromJson(json['sender']) : null;
    content = json['content'];
    type = json['type'];
    fileUrl = json['fileUrl'];
    readBy = json['readBy'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['chat'] = this.chat;
    if (this.sender != null) {
      data['sender'] = this.sender!.toJson();
    }
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

class Sender {
  String? sId;
  String? avatar;
  String? name;
  Sender({this.sId, this.avatar, this.name});

  Sender.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    avatar = json['avatar'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['avatar'] = this.avatar;
    data['name'] = this.name;
    return data;
  }
}