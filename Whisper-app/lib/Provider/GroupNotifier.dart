import 'package:flutter/material.dart';

class GroupNotifier extends ChangeNotifier {
  String _groupName = '';
  String _nickname = '';

  String get groupName => _groupName;
  String get nickname => _nickname;

  void updateGroupName(String newName) {
    _groupName = newName;
    notifyListeners();
  }

  void updateNickname(String newNickname) {
    _nickname = newNickname;
    notifyListeners();
  }
}