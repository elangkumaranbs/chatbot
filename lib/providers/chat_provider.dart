import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/gemini_service.dart';
import '../services/chat_history_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<Message> _messages = [];
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;
  String? _currentSessionId;
  bool _hasUnsavedChanges = false;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get currentSessionId => _currentSessionId;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  // Start a new chat session
  void startNewSession() {
    _currentSessionId = null;
    _messages.clear();
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // Load a chat session
  Future<void> loadSession(String sessionId) async {
    try {
      final sessionMessages = await ChatHistoryService.loadChatSession(
        sessionId,
      );
      if (sessionMessages != null) {
        _currentSessionId = sessionId;
        _messages.clear();
        _messages.addAll(sessionMessages);
        _hasUnsavedChanges = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading session: $e');
    }
  }

  // Save current session
  Future<String?> saveCurrentSession({String? title}) async {
    if (_messages.isEmpty) return null;

    try {
      String sessionId;
      if (_currentSessionId != null) {
        // Update existing session
        await ChatHistoryService.autoSaveSession(_currentSessionId!, _messages);
        sessionId = _currentSessionId!;
      } else {
        // Create new session
        sessionId = await ChatHistoryService.saveChatSession(
          _messages,
          sessionTitle: title,
        );
        _currentSessionId = sessionId;
      }

      _hasUnsavedChanges = false;
      notifyListeners();
      return sessionId;
    } catch (e) {
      print('Error saving session: $e');
      return null;
    }
  }

  // Auto-save current session (called periodically)
  Future<void> autoSave() async {
    if (_currentSessionId != null &&
        _hasUnsavedChanges &&
        _messages.isNotEmpty) {
      try {
        await ChatHistoryService.autoSaveSession(_currentSessionId!, _messages);
        _hasUnsavedChanges = false;
      } catch (e) {
        print('Error auto-saving: $e');
      }
    }
  }

  // Add a user message and generate AI response
  Future<void> sendMessage(
    String text, {
    String? imageUrl,
    String? fileUrl,
    String? fileType,
    String? fileName,
  }) async {
    if (text.trim().isEmpty && imageUrl == null && fileUrl == null) return;

    // Add user message
    final userMessage = Message(
      text: text,
      isUser: true,
      imageUrl: imageUrl,
      fileUrl: fileUrl,
      fileType: fileType,
      fileName: fileName,
    );
    _messages.add(userMessage);
    notifyListeners();

    // Set loading state
    _isLoading = true;
    notifyListeners();

    try {
      // Get AI response
      final response = await _geminiService.generateResponse(_messages);

      // Add AI response
      final aiMessage = Message(text: response, isUser: false);
      _messages.add(aiMessage);
    } catch (e) {
      // Handle error
      final errorMessage = Message(
        text: 'Sorry, I encountered an error. Please try again.',
        isUser: false,
      );
      _messages.add(errorMessage);
    } finally {
      // Reset loading state
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear all messages
  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}
