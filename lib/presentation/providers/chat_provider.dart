// lib/presentation/providers/chat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:pulse/data/models/chat_message_model.dart';
import 'package:pulse/services/gemini_ai_service.dart';
import 'package:pulse/services/chat_context_service.dart';
import 'package:pulse/presentation/providers/auth_provider.dart';

// Services
final geminiServiceProvider = Provider((ref) => GeminiAIService());
final chatContextServiceProvider = Provider((ref) => ChatContextService());

// Chat state
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool hasLocation;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.error,
    this.hasLocation = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool? hasLocation,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasLocation: hasLocation ?? this.hasLocation,
    );
  }
}

// Chat controller
class ChatController extends StateNotifier<ChatState> {
  final GeminiAIService _geminiService;
  final ChatContextService _contextService;
  final String? _userId;

  ChatController(
    this._geminiService,
    this._contextService,
    this._userId,
  ) : super(ChatState(messages: [])) {
    _initializeChat();
  }

  void _initializeChat() async {
    // Add welcome message
    final welcomeMessage = ChatMessage.ai(
      'Hello! I\'m your AI medical assistant. I can help you:\n\n'
      '• Find the nearest hospital to your location\n'
      '• Check real-time bed availability\n'
      '• Provide emergency guidance\n'
      '• Answer general health questions\n\n'
      'How can I help you today?',
    );
    
    state = state.copyWith(
      messages: [welcomeMessage],
    );

    // Check location permission and load context
    await _loadInitialContext();
  }

  Future<void> _loadInitialContext() async {
    try {
      final context = await _contextService.getHospitalContext();
      state = state.copyWith(hasLocation: context['hasLocation'] ?? false);
      
      if (context['hospitals'] != null && (context['hospitals'] as List).isNotEmpty) {
        final hospitalCount = (context['hospitals'] as List).length;
        final contextMessage = ChatMessage.ai(
          'I can see $hospitalCount ${hospitalCount == 1 ? 'hospital' : 'hospitals'} nearby. '
          '${state.hasLocation ? "I've detected your location." : "Enable location for distance information."} '
          'Feel free to ask me anything!',
        );
        
        state = state.copyWith(
          messages: [...state.messages, contextMessage],
        );
      }
    } catch (e) {
      print('Error loading initial context: $e');
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage.user(message, userId: _userId);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    // Save to Firebase
    if (_userId != null) {
      await _contextService.saveChatMessage(_userId, message, 'user');
    }

    try {
      // Get fresh hospital context with location
      print('🔄 Fetching fresh hospital context...');
      final context = await _contextService.getHospitalContext();
      
      if (context['error'] != null) {
        final errorMessage = ChatMessage.ai(
          'I\'m having trouble accessing hospital data right now. ${context['error']} Please try again later.',
        );
        
        state = state.copyWith(
          messages: [...state.messages, errorMessage],
          isLoading: false,
        );
        return;
      }

      print('✅ Context loaded, sending to Gemini...');
      
      // Send to Gemini with context
      final response = await _geminiService.sendMessage(
        message,
        context: context,
      );

      // Add AI response
      final aiMessage = ChatMessage.ai(response, metadata: context);
      
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        hasLocation: context['hasLocation'] ?? false,
      );

      // Save AI response to Firebase
      if (_userId != null) {
        await _contextService.saveChatMessage(_userId, response, 'ai');
      }
    } catch (e) {
      print('❌ Error in sendMessage: $e');
      
      final errorMessage = ChatMessage.ai(
        'I apologize, but I encountered an error. Please try again.',
      );
      
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }

  Future<void> sendQuickAction(String action) async {
    state = state.copyWith(isLoading: true);

    try {
      print('⚡ Quick action: $action');
      
      // Get fresh context
      final context = await _contextService.getHospitalContext();
      
      if (context['error'] != null) {
        final errorMessage = ChatMessage.ai(
          'I\'m unable to access hospital data at the moment. Please ensure hospitals are registered in the system.',
        );
        
        state = state.copyWith(
          messages: [...state.messages, errorMessage],
          isLoading: false,
        );
        return;
      }

      final response = await _geminiService.getQuickActionResponse(action, context);

      final aiMessage = ChatMessage.ai(response, metadata: context);
      
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      print('❌ Error in sendQuickAction: $e');
      
      final errorMessage = ChatMessage.ai(
        'I encountered an error processing your request. Please try again.',
      );
      
      state = state.copyWith(
        messages: [...state.messages, errorMessage],
        isLoading: false,
      );
    }
  }

  void resetChat() {
    _geminiService.resetChat();
    _initializeChat();
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  final geminiService = ref.watch(geminiServiceProvider);
  final contextService = ref.watch(chatContextServiceProvider);
  final user = ref.watch(currentUserProvider).value;
  
  return ChatController(geminiService, contextService, user?.id);
});