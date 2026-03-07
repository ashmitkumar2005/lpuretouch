import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickAccessService {
  static final QuickAccessService _instance = QuickAccessService._internal();
  factory QuickAccessService() => _instance;
  QuickAccessService._internal();

  static const String _storageKey = 'custom_quick_access_v1';
  
  // Default items if none are saved
  static const List<String> _defaultItems = [
    'Attendance',
    'Time table',
    'View Marks',
    'Fee Statement',
    'Result',
    'Assignment (CA)'
  ];

  final ValueNotifier<List<String>> selectedItemsNotifier = ValueNotifier([]);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_storageKey);
    if (saved != null && saved.isNotEmpty) {
      selectedItemsNotifier.value = saved;
    } else {
      selectedItemsNotifier.value = _defaultItems;
    }
  }

  Future<void> saveItems(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, items);
    selectedItemsNotifier.value = items;
  }

  Future<void> resetToDefault() async {
    await saveItems(_defaultItems);
  }
}
