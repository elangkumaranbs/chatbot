import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';

class ChatHistoryService {
  static const String _chatHistoryKey = 'chat_history';
  static const String _chatSessionsKey = 'chat_sessions';

  // Save a chat session
  static Future<String> saveChatSession(
    List<Message> messages, {
    String? sessionTitle,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Generate session ID
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    // Create session data
    final sessionData = {
      'id': sessionId,
      'title': sessionTitle ?? _generateSessionTitle(messages),
      'timestamp': DateTime.now().toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };

    // Get existing sessions
    final sessionsJson = prefs.getString(_chatSessionsKey) ?? '[]';
    final sessions = List<Map<String, dynamic>>.from(jsonDecode(sessionsJson));

    // Add new session
    sessions.insert(0, sessionData); // Insert at beginning for newest first

    // Keep only last 50 sessions to avoid storage issues
    if (sessions.length > 50) {
      sessions.removeRange(50, sessions.length);
    }

    // Save back to preferences
    await prefs.setString(_chatSessionsKey, jsonEncode(sessions));

    return sessionId;
  }

  // Load all chat sessions
  static Future<List<Map<String, dynamic>>> loadChatSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getString(_chatSessionsKey) ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(sessionsJson));
  }

  // Load a specific chat session
  static Future<List<Message>?> loadChatSession(String sessionId) async {
    final sessions = await loadChatSessions();
    final session = sessions.firstWhere(
      (s) => s['id'] == sessionId,
      orElse: () => {},
    );

    if (session.isEmpty) return null;

    final messagesJson = session['messages'] as List;
    return messagesJson.map((json) => Message.fromJson(json)).toList();
  }

  // Delete a chat session
  static Future<void> deleteChatSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await loadChatSessions();
    sessions.removeWhere((s) => s['id'] == sessionId);
    await prefs.setString(_chatSessionsKey, jsonEncode(sessions));
  }

  // Clear all chat history
  static Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatSessionsKey);
    await prefs.remove(_chatHistoryKey);
  }

  // Generate a session title from messages
  static String _generateSessionTitle(List<Message> messages) {
    if (messages.isEmpty) return 'New Chat';

    // Find the first user message
    final userMessage = messages.firstWhere(
      (msg) => msg.isUser,
      orElse: () => messages.first,
    );

    // Take first 30 characters and clean up
    String title = userMessage.text.trim();
    if (title.length > 30) {
      title = '${title.substring(0, 30)}...';
    }

    return title.isEmpty ? 'New Chat' : title;
  }

  // Update session title
  static Future<void> updateSessionTitle(
    String sessionId,
    String newTitle,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await loadChatSessions();

    final sessionIndex = sessions.indexWhere((s) => s['id'] == sessionId);
    if (sessionIndex != -1) {
      sessions[sessionIndex]['title'] = newTitle;
      await prefs.setString(_chatSessionsKey, jsonEncode(sessions));
    }
  }

  // Auto-save current session (called periodically)
  static Future<void> autoSaveSession(
    String sessionId,
    List<Message> messages,
  ) async {
    if (messages.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final sessions = await loadChatSessions();

    final sessionIndex = sessions.indexWhere((s) => s['id'] == sessionId);
    if (sessionIndex != -1) {
      sessions[sessionIndex]['messages'] = messages
          .map((msg) => msg.toJson())
          .toList();
      sessions[sessionIndex]['timestamp'] = DateTime.now().toIso8601String();
      await prefs.setString(_chatSessionsKey, jsonEncode(sessions));
    }
  }
}
