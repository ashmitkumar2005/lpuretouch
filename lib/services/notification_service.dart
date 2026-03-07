import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _seenAnnouncementsKey = 'seen_announcements';
  static const String _seenMessagesKey = 'seen_messages';

  final ValueNotifier<bool> hasUnreadAnnouncements = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hasUnreadMessages = ValueNotifier<bool>(false);

  final AuthService _authService = AuthService();

  Future<void> init() async {
    await refresh();
  }

  Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final seenAnnouncements = prefs.getStringList(_seenAnnouncementsKey) ?? [];
    final seenMessages = prefs.getStringList(_seenMessagesKey) ?? [];

    final announcements = await _authService.fetchAnnouncements();
    final messages = await _authService.fetchMyMessages();

    if (announcements != null && announcements.isNotEmpty) {
      bool anyUnread = false;
      for (var item in announcements) {
        final id = _getAnnouncementId(item);
        if (!seenAnnouncements.contains(id)) {
          anyUnread = true;
          break;
        }
      }
      hasUnreadAnnouncements.value = anyUnread;
    } else {
      hasUnreadAnnouncements.value = false;
    }

    if (messages != null && messages.isNotEmpty) {
      bool anyUnread = false;
      for (var item in messages) {
        final id = _getMessageId(item);
        if (!seenMessages.contains(id)) {
          anyUnread = true;
          break;
        }
      }
      hasUnreadMessages.value = anyUnread;
    } else {
      hasUnreadMessages.value = false;
    }
  }

  Future<void> markAnnouncementsAsSeen(List<dynamic> items) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_seenAnnouncementsKey) ?? [];
    
    for (var item in items) {
      final id = _getAnnouncementId(item);
      if (!seen.contains(id)) seen.add(id);
    }

    await prefs.setStringList(_seenAnnouncementsKey, seen);
    hasUnreadAnnouncements.value = false;
  }

  Future<void> markMessagesAsSeen(List<dynamic> items) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList(_seenMessagesKey) ?? [];

    for (var item in items) {
      final id = _getMessageId(item);
      if (!seen.contains(id)) seen.add(id);
    }

    await prefs.setStringList(_seenMessagesKey, seen);
    hasUnreadMessages.value = false;
  }

  String _getAnnouncementId(dynamic item) {
    // Try to find a unique ID, fallback to subject+date
    final id = item['AId'] ?? item['AnnouncementId'] ?? item['Id'];
    if (id != null) return id.toString();
    return '${item['Subject']}_${item['EntryDate']}';
  }

  String _getMessageId(dynamic item) {
    final id = item['Id'] ?? item['MessageId'] ?? item['MId'];
    if (id != null) return id.toString();
    return '${item['Subject']}_${item['Date']}';
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seenAnnouncementsKey);
    await prefs.remove(_seenMessagesKey);
    hasUnreadAnnouncements.value = false;
    hasUnreadMessages.value = false;
  }
}
