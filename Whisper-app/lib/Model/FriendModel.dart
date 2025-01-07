class FriendModel {
  String? sId;
  Requester? requester;
  String? recipient;
  String? status;
  String? createdAt;
  String? updatedAt;
  int? iV;

  FriendModel(
      {this.sId,
      this.requester,
      this.recipient,
      this.status,
      this.createdAt,
      this.updatedAt,
      this.iV});

  FriendModel.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    requester = json['requester'] != null
        ? new Requester.fromJson(json['requester'])
        : null;
    recipient = json['recipient'];
    status = json['status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    if (this.requester != null) {
      data['requester'] = this.requester!.toJson();
    }
    data['recipient'] = this.recipient;
    data['status'] = this.status;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}

class Requester {
  String? sId;
  String? email;
  String? phoneNumber;
  String? name;
  String? avatar;

  Requester({this.sId, this.email, this.phoneNumber, this.name, this.avatar});

  Requester.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    email = json['email'];
    phoneNumber = json['phoneNumber'];
    name = json['name'];
    avatar = json['avatar'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['email'] = this.email;
    data['phoneNumber'] = this.phoneNumber;
    data['name'] = this.name;
    data['avatar'] = this.avatar;
    return data;
  }
}
