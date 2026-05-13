import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class QuestsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _sideQuests = [];
  String _sideQuestDate = "";

  List<Map<String, dynamic>> get sideQuests => _sideQuests;

  Future<void> loadSideQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final String savedDate = prefs.getString('side_quest_date') ?? "";
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (savedDate != today) {
      _sideQuests = [];
      _sideQuestDate = today;
      await prefs.setString('side_quest_date', today);
      await prefs.remove('side_quests_list');
    } else {
      final String? data = prefs.getString('side_quests_list');
      if (data != null) {
        _sideQuests = List<Map<String, dynamic>>.from(json.decode(data));
      }
    }
    notifyListeners();
  }

  Future<void> _saveSideQuestsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('side_quests_list', json.encode(_sideQuests));
    await prefs.setString('side_quest_date', _sideQuestDate);
  }

  void addSideQuest(String title) {
    if (_sideQuestDate.isEmpty) {
      _sideQuestDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
    _sideQuests.add({'title': title, 'isDone': false});
    _saveSideQuestsToStorage();
    notifyListeners();
  }

  void toggleSideQuestStatus(int index, bool isDone) {
    if (index >= 0 && index < _sideQuests.length) {
      _sideQuests[index]['isDone'] = isDone;
      _saveSideQuestsToStorage();
      notifyListeners();
    }
  }

  void deleteSideQuest(int index) {
    if (index >= 0 && index < _sideQuests.length) {
      _sideQuests.removeAt(index);
      _saveSideQuestsToStorage();
      notifyListeners();
    }
  }
}