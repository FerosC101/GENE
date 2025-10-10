import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiAIService {
  static const String apiKey = 'AIzaSyDsqyQ_IlhJfjzGN6YXNONMq3e0c87RqEk';
  
  // Use the correct Gemini model names
  static const String _modelName = 'gemini-2.0-flash-001'; // or 'gemini-1.5-flash' for faster responses
  
  // Stores conversation messages
  final List<Map<String, dynamic>> _conversationHistory = [];

  GeminiAIService() {
    _initializeChat();
  }

  /// Initialize chat with system prompt
  void _initializeChat() {
    _conversationHistory.clear();
    
    // For Gemini, we start with just the system prompt
    _conversationHistory.add({
      'role': 'user',
      'parts': [
        {'text': _getSystemPrompt()}
      ],
    });
  }

  String _getSystemPrompt() {
    return '''
You are an AI Medical Assistant for MedMap AI - Smart Hospital Management System in Calamba, Laguna, Philippines.

STRICT RULES:
1. ONLY answer questions about:
   - Hospital services and facilities in Calamba, Laguna
   - Finding hospitals and doctors
   - Booking appointments
   - Medical emergencies and first aid
   - General health information
   - MedMap AI app features

2. DO NOT answer:
   - Non-medical topics
   - Specific medical diagnoses (refer to doctors)
   - Prescription medications

3. Always be professional, empathetic, and concise
4. In emergencies, recommend calling emergency services

Keep responses under 200 words and conversational.
''';
  }

  /// Send a message to the AI
  Future<String> sendMessage(String message,
      {Map<String, dynamic>? context}) async {
    try {
      // Add context if provided
      String enhancedMessage = message;
      if (context != null && context.isNotEmpty) {
        enhancedMessage += '\n\nContext: ${_formatContext(context)}';
      }

      // Call the API
      final responseText = await _callModel(enhancedMessage);

      if (responseText != null) {
        return responseText;
      }

      return 'I apologize, I cannot respond at the moment. Please try again.';
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      return 'I encountered an error. Please try again later.';
    }
  }

  /// Call the Gemini model
  Future<String?> _callModel(String message) async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$apiKey',
      );

      // Prepare the request with conversation history
      final contents = [
        {
          'parts': [
            {'text': '${_getSystemPrompt()}\n\n$message'}
          ]
        }
      ];

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
            'topP': 0.8,
            'topK': 40,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty && 
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          debugPrint('❌ No valid response: ${response.body}');
        }
      } else {
        debugPrint('❌ API failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ API error: $e');
    }

    return null;
  }

  /// Format context for the message
  String _formatContext(Map<String, dynamic> context) {
    final buffer = StringBuffer();

    if (context.containsKey('nearbyHospitals')) {
      buffer.write('Nearby hospitals: ${context['nearbyHospitals']}. ');
    }
    if (context.containsKey('userLocation')) {
      buffer.write('User location: ${context['userLocation']}. ');
    }
    if (context.containsKey('availableBeds')) {
      buffer.write('Available beds: ${context['availableBeds']}. ');
    }

    return buffer.toString();
  }

  /// Quick action responses
  Future<String> getQuickActionResponse(String action) async {
    switch (action) {
      case 'Find nearest hospital':
        return await sendMessage(
            'I need to find the nearest hospital. Can you help me locate one?');
      case 'Check ICU availability':
        return await sendMessage('Show me hospitals with available ICU beds');
      case 'Emergency routing':
        return await sendMessage(
            'I have a medical emergency. Guide me to the nearest hospital.');
      case 'Book appointment':
        return await sendMessage(
            'I want to book a doctor appointment. What information do you need?');
      default:
        return await sendMessage(action);
    }
  }

  /// Reset the conversation
  void resetChat() {
    _initializeChat();
  }
}