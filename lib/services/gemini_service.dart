import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class GeminiService {
  // API key for Gemini models
  static const String apiKey = 'AIzaSyAgNydkXojju047E4aYu6T7MROHUttWMUw';

  // Primary model URLs (Gemini 2.0 Flash - Latest model with enhanced capabilities)
  static const String primaryMultimodalUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';
  static const String primaryTextUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

  // Fallback model URLs (Gemini 1.5 Flash - stable fallback)
  static const String fallbackMultimodalUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  static const String fallbackTextUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  Future<String> generateResponse(List<Message> conversation) async {
    try {
      // Check if the last user message contains an image
      final Message lastUserMessage = conversation.lastWhere(
        (msg) => msg.isUser,
      );
      final bool hasImage = lastUserMessage.imageUrl != null;

      print('=== Starting Gemini API Request ===');
      print('Has image: $hasImage');

      // Try primary model first, then fallback if needed
      String response = await _tryWithFallback(conversation, hasImage);
      print('=== Final response ready ===');
      return response;
    } catch (e) {
      print('Exception in generateResponse: $e');
      return 'Sorry, I encountered an unexpected error. Please try again later.';
    }
  }

  Future<String> _tryWithFallback(
    List<Message> conversation,
    bool hasImage,
  ) async {
    // Try primary model first
    final String primaryUrl = hasImage ? primaryMultimodalUrl : primaryTextUrl;
    final String fallbackUrl =
        hasImage ? fallbackMultimodalUrl : fallbackTextUrl;

    // First attempt with primary model
    try {
      print(
        'Trying primary model: ${hasImage ? "gemini-2.0-flash-exp" : "gemini-2.0-flash-exp"}',
      );
      final response = await _generateWithModel(
        conversation,
        hasImage,
        primaryUrl,
      );

      // Check if the response indicates a failure that should trigger fallback
      if (_shouldTriggerFallback(response)) {
        print('Primary model failed: $response');
      } else {
        // Success with primary model
        print('Primary model succeeded');
        return response;
      }
    } catch (e) {
      print('Primary model exception: $e');
    }

    // Fallback to more stable model
    try {
      print(
        'Using fallback model: ${hasImage ? "gemini-1.5-flash" : "gemini-1.5-flash"}',
      );
      final fallbackResponse = await _generateWithModel(
        conversation,
        hasImage,
        fallbackUrl,
      ); // Check if fallback also failed
      if (_shouldTriggerFallback(fallbackResponse)) {
        print('Fallback model also failed: $fallbackResponse');
        // Both models failed - return appropriate error message based on the most specific error
        if (fallbackResponse.contains('quota') ||
            fallbackResponse.contains('RESOURCE_EXHAUSTED')) {
          return 'AI service is currently at capacity. Please try again in a few minutes.';
        } else if (fallbackResponse.contains(
              'Service temporarily unavailable',
            ) ||
            fallbackResponse.contains('model is overloaded')) {
          return 'AI service is temporarily unavailable. Please try again later.';
        } else {
          return 'Unable to process your request at the moment. Please try again.';
        }
      }

      print('Fallback model succeeded');
      return fallbackResponse;
    } catch (e) {
      print('Fallback model exception: $e');
      return 'Sorry, I\'m having trouble connecting to the AI service. Please try again in a moment.';
    }
  }

  bool _shouldTriggerFallback(String response) {
    return response.contains('Service temporarily unavailable') ||
        response.contains('model is overloaded') ||
        response.contains('Service is currently busy') ||
        response.contains('quota exceeded') ||
        response.contains('RESOURCE_EXHAUSTED') ||
        response.contains('503') ||
        response.contains('502') ||
        response.contains('500');
  }

  Future<String> _generateWithModel(
    List<Message> conversation,
    bool hasImage,
    String apiUrl,
  ) async {
    // Format the conversation history for the API
    final List<Map<String, dynamic>> messages = [];

    if (hasImage) {
      final Message lastUserMessage = conversation.lastWhere(
        (msg) => msg.isUser,
      );

      // Create parts array for the message
      final List<Map<String, dynamic>> parts = [];

      // Add text content if available
      if (lastUserMessage.text.isNotEmpty) {
        parts.add({'text': lastUserMessage.text});
      }

      // Add image content
      String normalizedPath = lastUserMessage.imageUrl!;

      // Handle various URI formats and normalize paths
      if (normalizedPath.startsWith('file://')) {
        normalizedPath = normalizedPath.substring(7);
      }

      // Handle data URLs
      if (normalizedPath.startsWith('data:')) {
        final int commaIndex = normalizedPath.indexOf(',');
        if (commaIndex != -1) {
          final String base64Data = normalizedPath.substring(commaIndex + 1);
          final String mimeType =
              normalizedPath.substring(5, commaIndex).split(';')[0];
          if (mimeType.startsWith('image/')) {
            try {
              // Validate base64 data by attempting to decode it
              base64Decode(base64Data);
              parts.add({
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Data, // Already base64 encoded
                },
              });
              messages.add({'role': 'user', 'parts': parts});
              return await _makeApiRequest(messages, apiUrl);
            } catch (e) {
              print('Error decoding base64 image data: $e');
              return 'Sorry, there was an error processing the image data.';
            }
          }
        }
        return 'Sorry, invalid image data format.';
      }

      // Handle file system paths
      try {
        normalizedPath = Uri.decodeFull(normalizedPath);
        final File imageFile = File(normalizedPath);

        if (await imageFile.exists()) {
          final List<int> imageBytes = await imageFile.readAsBytes();
          String? mimeType = lookupMimeType(normalizedPath);

          if (mimeType == null) {
            final extension = path.extension(normalizedPath).toLowerCase();
            switch (extension) {
              case '.jpg':
              case '.jpeg':
                mimeType = 'image/jpeg';
                break;
              case '.png':
                mimeType = 'image/png';
                break;
              case '.gif':
                mimeType = 'image/gif';
                break;
              case '.webp':
                mimeType = 'image/webp';
                break;
              case '.bmp':
                mimeType = 'image/bmp';
                break;
            }
          }

          if (mimeType != null && mimeType.startsWith('image/')) {
            parts.add({
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(imageBytes),
              },
            });
          } else {
            return 'Sorry, unsupported image format.';
          }
        } else {
          return 'Sorry, image file not found.';
        }
      } catch (e) {
        print('Error processing image file: $e');
        return 'Sorry, there was an error processing the image file.';
      }

      // For Gemini 2.0 Flash vision model with enhanced capabilities
      final userText = lastUserMessage.text.trim();

      // Enhanced context understanding for Gemini 2.0 Flash
      final isTextExtractionRequest =
          userText.toLowerCase().contains('extract') ||
          userText.toLowerCase().contains('text') ||
          userText.toLowerCase().contains('read') ||
          userText.toLowerCase().contains('ocr') ||
          userText.toLowerCase().contains('transcribe') ||
          userText.isEmpty;

      final isAnalysisRequest =
          userText.toLowerCase().contains('analyze') ||
          userText.toLowerCase().contains('describe') ||
          userText.toLowerCase().contains('explain') ||
          userText.toLowerCase().contains('what') ||
          userText.toLowerCase().contains('how');

      if (isTextExtractionRequest && userText.isEmpty) {
        parts.insert(0, {
          'text':
              'Please extract and provide all the text content from this image with high accuracy. If there is no text, provide a detailed description of what you see in the image, including objects, people, scenes, colors, and any notable details.',
        });
      } else if (isTextExtractionRequest) {
        parts.insert(0, {
          'text':
              '$userText. Please focus on extracting any text content from the image with high accuracy and attention to detail.',
        });
      } else if (isAnalysisRequest) {
        parts.insert(0, {
          'text':
              '$userText. Please provide a comprehensive analysis of this image, including detailed descriptions, context, and any relevant insights.',
        });
      }

      messages.add({'role': 'user', 'parts': parts});
    } else {
      // For text-only conversations, include optimized conversation history
      final optimizedConversation = _optimizeConversationHistory(conversation);
      messages.addAll(
        optimizedConversation.map((message) {
          return {
            'role': message.isUser ? 'user' : 'model',
            'parts': [
              {'text': message.text},
            ],
          };
        }).toList(),
      );
    }

    return await _makeApiRequest(messages, apiUrl);
  }

  // Optimize conversation history for Gemini 2.0 Flash with better context retention
  List<Message> _optimizeConversationHistory(List<Message> conversation) {
    // For Gemini 2.0 Flash, we can handle more context efficiently
    // Keep last 10 messages (5 exchanges) for better conversation flow
    if (conversation.length <= 10) return conversation;

    // Get the last 10 messages for better context
    final startIndex = conversation.length - 10;
    final recent = conversation.sublist(startIndex);

    // Ensure we always start with a user message for proper conversation flow
    if (recent.isNotEmpty && !recent.first.isUser) {
      // If first message is assistant, remove it to maintain proper flow
      return recent.sublist(1);
    }

    return recent;
  }

  Future<String> _makeApiRequest(
    List<Map<String, dynamic>> messages,
    String apiUrl, {
    int maxRetries = 2, // Reduced retries since we have fallback
    int retryDelaySeconds = 1, // Faster retry for better UX
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final Map<String, dynamic> requestBody = {
          'contents': messages,
          'generationConfig': {
            'temperature': 0.8, // Increased for better creativity in 2.0 Flash
            'topK': 64, // Increased for better diversity
            'topP': 0.95,
            'maxOutputTokens':
                1024, // Increased for longer responses with 2.0 Flash
            'candidateCount': 1,
            'stopSequences': [],
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
            },
          ],
        };

        print(
          'Making API request to: ${apiUrl.contains('2.0-flash-exp')
              ? 'Gemini 2.0 Flash'
              : apiUrl.contains('1.5-flash')
              ? 'Gemini 1.5 Flash'
              : 'Gemini Pro'} (attempt ${attempt + 1}/$maxRetries)',
        );

        final response = await http
            .post(
              Uri.parse('$apiUrl?key=$apiKey'),
              headers: {
                'Content-Type': 'application/json',
                'User-Agent': 'GeminiChatApp/1.0',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(
              Duration(seconds: 30), // 30 second timeout
              onTimeout: () {
                throw Exception('Request timeout');
              },
            );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);

          // Check if response has the expected structure
          if (data['candidates'] != null &&
              data['candidates'].isNotEmpty &&
              data['candidates'][0]['content'] != null &&
              data['candidates'][0]['content']['parts'] != null &&
              data['candidates'][0]['content']['parts'].isNotEmpty) {
            final result = data['candidates'][0]['content']['parts'][0]['text'];
            print('API request successful');
            return result;
          } else {
            return 'Sorry, I received an unexpected response format. Please try again.';
          }
        } else {
          print('API Error: ${response.statusCode} - ${response.body}');

          // Handle specific error codes with user-friendly messages
          switch (response.statusCode) {
            case 400:
              return 'Invalid request. Please check your message and try again.';
            case 403:
              return 'API access denied. Please check your API key.';
            case 429:
              // Check if it's a quota exhaustion error
              final errorBody = response.body;
              if (errorBody.contains('quota') ||
                  errorBody.contains('RESOURCE_EXHAUSTED')) {
                return 'API quota exceeded. Please wait a few minutes before trying again.';
              }
              // For rate limits, trigger fallback instead of retrying same model
              return 'Service is currently busy. Please try again.';
            case 503:
              // For 503 errors, return a message that triggers fallback
              return 'Service temporarily unavailable. Please try again later.';
            case 500:
              return 'Server error. Please try again in a few moments.';
            default:
              return 'Sorry, I encountered an error (${response.statusCode}). Please try again later.';
          }
        }
      } catch (e) {
        print('API Exception on attempt ${attempt + 1}: $e');

        // For timeouts and certain network issues, retry with longer delay
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('timeout') ||
            errorString.contains('connection refused') ||
            errorString.contains('network unreachable')) {
          print('Network issue detected: $e');

          if (attempt < maxRetries - 1) {
            print('Network issue, retrying with longer delay...');
            await Future.delayed(Duration(seconds: retryDelaySeconds * 2));
            continue;
          }
        }

        // For other exceptions, retry with normal delay
        if (attempt < maxRetries - 1) {
          print('Retrying due to error: $e');
          await Future.delayed(Duration(seconds: retryDelaySeconds));
          retryDelaySeconds *= 2; // Exponential backoff
        }
      }
    }

    return 'encountered an error';
  }
}
