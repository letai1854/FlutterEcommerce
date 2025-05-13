import 'package:e_commerce_app/constants.dart'; // Assuming constants.dart is in lib
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiChatService {
  late GenerativeModel _model;
  late ChatSession _chatSession;

  GeminiChatService() {
    if (geminiApiKey == "YOUR_GEMINI_API_KEY") {
      // Potentially throw an error or handle this case if the API key is not set.
      // For now, we'll proceed, but API calls will fail.
      print("Warning: Gemini API Key is not set in constants.dart. API calls will fail.");
    }
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Using gemini-1.5-flash
      apiKey: geminiApiKey,
    );
    _startChatSession();
  }

  void _startChatSession() {
    // Initialize with a system instruction or initial history if needed
    _chatSession = _model.startChat(history: [
      Content.text("You are a helpful and friendly AI assistant for an e-commerce platform. Be concise and helpful.")
    ]);
  }

  Future<String?> sendMessage(String message) async {
    try {
      final response = await _chatSession.sendMessage(
        Content.text(message),
      );
      return response.text;
    } catch (e) {
      print("Error sending message to Gemini: $e");
      return "Sorry, I encountered an error. Please try again.";
    }
  }

  void resetChatSession() {
    _startChatSession(); // Re-initializes the chat session, effectively clearing history for the new session
  }

  // Optional: To get the history if needed elsewhere, though ChatSession manages it internally.
  List<Content> getHistory() {
    return _chatSession.history.toList();
  }
}
