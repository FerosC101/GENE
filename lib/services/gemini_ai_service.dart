// lib/services/gemini_ai_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiAIService {
  static const String apiKey = 'AIzaSyBgePDAyyEv2c4OR-iMxY1P_ge6QDOsC8s';
  
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiAIService() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-001',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );

    _initializeChat();
  }

  void _initializeChat() {
    _chat = _model.startChat(history: [
      Content.text(_getSystemPrompt()),
    ]);
  }

  String _getSystemPrompt() {
    return '''
You are an AI Medical Assistant for MedMap AI - Smart Hospital Management System in the Philippines.

STRICT RULES YOU MUST FOLLOW:
1. ONLY answer questions related to:
   - Hospital services and facilities
   - Finding hospitals based on real data provided
   - Medical emergencies and first aid guidance
   - General health information (non-diagnostic)
   - Using the MedMap AI app features
   - Hospital bed availability from real-time data
   
2. DO NOT answer questions about:
   - Non-medical topics (politics, entertainment, sports, etc.)
   - Specific medical diagnoses (always recommend seeing a doctor)
   - Prescription medications (refer to healthcare professionals)
   - Booking appointments (feature not yet available - tell users it's coming soon)
   - Personal advice unrelated to healthcare
   
3. When user asks about hospitals:
   - Use ONLY the real hospital data provided in the context
   - Never make up or assume hospital information
   - If no data is provided, say "I don't have current hospital data available"
   
4. If asked about non-medical topics, respond EXACTLY:
   "I'm specialized in healthcare and hospital services through MedMap AI. I can help you find hospitals, check bed availability, or provide general health guidance. How can I assist you with medical services?"

5. Always be:
   - Professional and empathetic
   - Clear and concise (keep responses under 150 words)
   - Safety-conscious (in emergencies, recommend calling emergency services: 911 or 8-911-1406 for Philippines)
   
6. Location-based queries:
   - When user asks for "nearest hospital", use the distance data provided
   - Always mention the distance in kilometers
   - Recommend the closest operational hospital

RESPONSE FORMAT:
- Keep responses under 150 words
- Use bullet points for lists of 3+ items
- Be conversational but professional
- NEVER mention that you're using provided data or context

CRITICAL: Base ALL hospital information on the context data provided. Do not invent hospital names, addresses, or availability.
''';
  }

  Future<String> sendMessage(
    String message, {
    Map<String, dynamic>? context,
  }) async {
    try {
      String enhancedMessage = message;
      
      // Add context if provided
      if (context != null && context.isNotEmpty) {
        enhancedMessage += '\n\n[SYSTEM CONTEXT - Use this real data to answer]:';
        
        if (context.containsKey('hospitals') && context['hospitals'] != null) {
          final hospitals = context['hospitals'] as List;
          enhancedMessage += '\n\nAvailable Hospitals (${hospitals.length} total):';
          
          for (var i = 0; i < hospitals.length; i++) {
            final hospital = hospitals[i];
            enhancedMessage += '''
\n${i + 1}. ${hospital['name']}
   - Distance: ${hospital['distance']?.toStringAsFixed(1) ?? 'unknown'} km away
   - ICU Available: ${hospital['icuAvailable']}/${hospital['icuTotal']}
   - ER Available: ${hospital['erAvailable']}/${hospital['erTotal']}
   - Wait Time: ${hospital['waitTime']} minutes
   - Status: ${hospital['isOperational'] ? 'Open' : 'Closed'}
   - Address: ${hospital['address']}
   - Phone: ${hospital['phone']}''';
          }
        }
        
        if (context.containsKey('userLocation')) {
          enhancedMessage += '\n\nUser Location: ${context['userLocation']}';
        }
        
        if (context.containsKey('totalStats')) {
          final stats = context['totalStats'];
          enhancedMessage += '\n\nSystem-wide Statistics:';
          enhancedMessage += '\n- Total ICU Available: ${stats['totalIcu']}';
          enhancedMessage += '\n- Total ER Available: ${stats['totalEr']}';
          enhancedMessage += '\n- Total Ward Available: ${stats['totalWard']}';
        }
      }

      print('📤 Sending to Gemini: $enhancedMessage');

      final response = await _chat.sendMessage(
        Content.text(enhancedMessage),
      );

      final responseText = response.text ?? 'I apologize, but I could not generate a response. Please try again.';
      
      print('📥 Received from Gemini: $responseText');
      
      return responseText;
    } catch (e) {
      print('❌ Gemini API Error: $e');
      return 'I encountered an error processing your request. Please try again or rephrase your question.';
    }
  }

  // Get quick action responses
  Future<String> getQuickActionResponse(String action, Map<String, dynamic>? context) async {
    switch (action) {
      case 'Find nearest hospital':
        return await sendMessage(
          'Show me the nearest hospital with available beds. I need emergency care.',
          context: context,
        );
      
      case 'Check ICU availability':
        return await sendMessage(
          'Which hospitals have ICU beds available right now? Show me the options.',
          context: context,
        );
      
      case 'Emergency routing':
        return await sendMessage(
          'I have a medical emergency. Which is the closest hospital I can go to immediately?',
          context: context,
        );
      
      default:
        return await sendMessage(action, context: context);
    }
  }

  void resetChat() {
    _initializeChat();
  }
}