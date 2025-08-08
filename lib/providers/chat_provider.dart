import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/gemini_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<Message> _messages = [];
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

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
