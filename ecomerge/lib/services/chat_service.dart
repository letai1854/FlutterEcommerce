import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:e_commerce_app/database/PageResponse.dart';
import 'package:e_commerce_app/database/database_helper.dart'; // For baseurl
import 'package:e_commerce_app/database/Storage/UserInfo.dart';
import 'package:e_commerce_app/models/chat/create_conversation_request_dto.dart';
import 'package:e_commerce_app/models/chat/conversation_dto.dart';
import 'package:e_commerce_app/models/chat/message_dto.dart';
import 'package:e_commerce_app/models/chat/send_message_request_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

// Top-level private no-op function for STOMP debug messages
void _stompDebugNoOp(String message) {
  // This function does nothing.
}

class ChatService {
  final String _chatApiBaseUrl = '$baseurl/api/chat'; // baseurl from database_helper
  final String _imagesApiBaseUrl = '$baseurl/api/images'; // For image uploads
  final String _webSocketUrl = '${baseurl.replaceFirst("http", "ws")}/ws/websocket'; // Adjust if baseurl includes https

  late http.Client _httpClient;
  StompClient? _stompClient;

  final UserInfo _userInfo = UserInfo();

  ChatService() {
    _httpClient = _createSecureClient();
  }

  http.Client _createSecureClient() {
    if (kIsWeb) {
      return http.Client();
    } else {
      final HttpClient ioClient = HttpClient()
        ..badCertificateCallback =
            ((X509Certificate cert, String host, int port) => true);
      return IOClient(ioClient);
    }
  }

  Map<String, String> _getAuthHeaders() {
    final token = _userInfo.authToken;
    if (token == null) {
      throw Exception('User not authenticated. Auth token is null.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // --- REST API Methods ---

  Future<ConversationDTO> startConversation(CreateConversationRequestDTO request) async {
    final url = Uri.parse('$_chatApiBaseUrl/conversations/start');
    try {
      final response = await _httpClient.post(
        url,
        headers: _getAuthHeaders(),
        body: jsonEncode(request.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ConversationDTO.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to start conversation: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error starting conversation: $e');
    }
  }

  Future<ConversationDTO?> getMyConversations() async {
    final url = Uri.parse('$_chatApiBaseUrl/conversations/me');
    try {
      final response = await _httpClient.get(url, headers: _getAuthHeaders());
      if (response.statusCode == 200) {
        try {
          final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
          // The TypeError "Null is not a subtype of type 'String'" likely originates from this next line.
          // Ensure ConversationDTO.fromJson correctly handles nullable fields from the JSON,
          // such as adminEmail, adminFullName, adminId, and lastMessage, by defining them as nullable
          // (e.g., String?, int?, LastMessageInfo?) in the Dart model and parsing them accordingly.
          return ConversationDTO.fromJson(decodedBody);
        } on TypeError catch (e, s) {
          // Log the error and the response body that caused it for easier debugging
          print('TypeError during JSON deserialization for getMyConversations: $e');
          print('Stacktrace: $s');
          print('Response body: ${utf8.decode(response.bodyBytes)}');
          // Re-throw a more specific exception
          throw Exception('Failed to parse user conversation response. Original error: $e');
        }
      } else if (response.statusCode == 404) {
        return null; // No conversation found for the user
      } else {
        throw Exception('Failed to get conversation: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // This will catch errors from _getAuthHeaders, _httpClient.get, network issues,
      // or the re-thrown exception from the new inner try-catch.
      throw Exception('Error getting conversation: $e');
    }
  }
  
  Future<PageResponse<ConversationDTO>> getAdminConversations({String? status, int page = 0, int size = 15, String sort = 'updatedDate,desc'}) async {
    String queryString = 'page=$page&size=$size&sort=$sort';
    if (status != null && status.isNotEmpty) {
      queryString += '&status=$status';
    }
    final url = Uri.parse('$_chatApiBaseUrl/conversations/admin?$queryString'); 
    try {
      final response = await _httpClient.get(url, headers: _getAuthHeaders());
      if (response.statusCode == 200) {
        return PageResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)), ConversationDTO.fromJson);
      } else {
        throw Exception('Failed to get admin conversations: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting admin conversations: $e');
    }
  }

  Future<ConversationDTO> updateConversationStatus(int conversationId, String newStatus) async {
    final url = Uri.parse('$_chatApiBaseUrl/conversations/$conversationId/status?newStatus=$newStatus');
     try {
      final response = await _httpClient.patch(url, headers: _getAuthHeaders());
      if (response.statusCode == 200) {
        return ConversationDTO.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to update conversation status: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating conversation status: $e');
    }
  }


  Future<PageResponse<MessageDTO>> getMessagesForConversation(int conversationId, {int page = 0, int size = 20, String sort = 'sendTime,desc'}) async {
    final url = Uri.parse('$_chatApiBaseUrl/conversations/$conversationId/messages?page=$page&size=$size&sort=$sort');
    try {
      final response = await _httpClient.get(url, headers: _getAuthHeaders());
      if (response.statusCode == 200) {
        return PageResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)), MessageDTO.fromJson);
      } else {
        throw Exception('Failed to get messages: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting messages: $e');
    }
  }

  Future<MessageDTO> sendMessageREST(SendMessageRequestDTO request) async {
    final url = Uri.parse('$_chatApiBaseUrl/messages/send');
    try {
      final response = await _httpClient.post(
        url,
        headers: _getAuthHeaders(),
        body: jsonEncode(request.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return MessageDTO.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to send message via REST: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending message via REST: $e');
    }
  }

  // --- Image Upload ---
  Future<String?> uploadImage(List<int> imageBytes, String fileName) async {
    final url = Uri.parse('$_imagesApiBaseUrl/upload');
    try {
      final request = http.MultipartRequest('POST', url);
      final token = _userInfo.authToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: fileName));
      
      // Use the custom _httpClient for sending the multipart request
      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData['imagePath'] as String?; // e.g., "/api/images/filename.jpg"
      } else {
        print('Failed to upload image: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  String getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      // Return a placeholder or handle appropriately
      return 'https://via.placeholder.com/150'; 
    }
    // relativePath is like "/api/images/filename.jpg"
    // baseurl is like "https://localhost:8443"
    return '$baseurl$relativePath';
  }

  // --- WebSocket Methods ---
  void connectWebSocket({
    required Function(StompFrame) onConnect,
    required Function(dynamic) onError,
    required Function(StompFrame) onWebSocketError,
  }) {
    final token = _userInfo.authToken;
    if (token == null) {
      onError('Auth token not found for WebSocket connection.');
      return;
    }

    final stompConnectHeaders = {'Authorization': 'Bearer $token'};
    final webSocketConnectHeaders = {'Authorization': 'Bearer $token'};

    Future<WebSocketChannel> customConnectorForNative() async {
      // This function will be used for webSocketConnector on non-web platforms
      final client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      
      // Convert Map<String, String> to Map<String, dynamic> for WebSocket.connect
      final Map<String, dynamic> dynamicHeaders = Map<String, dynamic>.from(webSocketConnectHeaders);

      final webSocket = await WebSocket.connect(
        _webSocketUrl,
        headers: dynamicHeaders,
        customClient: client,
      );
      return IOWebSocketChannel(webSocket);
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: _webSocketUrl,
        onConnect: onConnect,
        onWebSocketError: (dynamic error) => onError(error.toString()),
        stompConnectHeaders: stompConnectHeaders,
        webSocketConnectHeaders: webSocketConnectHeaders, // Still useful for default web connector
        onDebugMessage: kDebugMode 
            ? (String message) => print("STOMP_DEBUG: $message") 
            : _stompDebugNoOp,
      ),
    );
    _stompClient?.activate();
  }

  StompUnsubscribe? subscribeToConversation(
    int conversationId, 
    Function(MessageDTO message) onMessageReceived,
    Function(dynamic joinNotification) onJoinNotification, // Assuming JoinNotification DTO
    Function(dynamic error) onErrorCallback
  ) {
    if (_stompClient == null || !_stompClient!.connected) {
      print('STOMP client not connected. Cannot subscribe.');
      return null;
    }
    return _stompClient?.subscribe(
      destination: '/topic/conversation/$conversationId',
      callback: (frame) {
        try {
          final data = jsonDecode(frame.body!);
          // Differentiate message types, e.g., MessageDTO vs JoinNotification
          if (data['type'] == 'JOIN') { // Assuming JoinNotification has a 'type' field
             // onJoinNotification(JoinNotification.fromJson(data));
             print("Join notification received: ${frame.body}");
          } else if (data.containsKey('senderId')) { // Heuristic for MessageDTO
            onMessageReceived(MessageDTO.fromJson(data));
          } else {
            print("Received unknown message type on conversation topic: ${frame.body}");
          }
        } catch (e) {
          onErrorCallback('Error processing message from /topic/conversation/$conversationId: $e. Body: ${frame.body}');
        }
      },
    );
  }
  
  StompUnsubscribe? subscribeToErrors(Function(dynamic errorFrameBody) onErrorReceived) {
    if (_stompClient == null || !_stompClient!.connected) {
      print('STOMP client not connected. Cannot subscribe to errors.');
      return null;
    }
    return _stompClient?.subscribe(
      destination: '/topic/errors',
      callback: (frame) {
        onErrorReceived(frame.body);
      },
    );
  }

  StompUnsubscribe? subscribeToNewAdminConversations(
    Function(ConversationDTO conversation) onNewConversation,
    Function(dynamic error) onErrorCallback
  ) {
    if (_stompClient == null || !_stompClient!.connected) {
      print('STOMP client not connected. Cannot subscribe to new admin conversations.');
      return null;
    }
    return _stompClient?.subscribe(
      destination: '/topic/admin/conversations/new',
      callback: (frame) {
        try {
          final data = jsonDecode(frame.body!);
          final conversation = ConversationDTO.fromJson(data);
          onNewConversation(conversation);
        } catch (e) {
          onErrorCallback('Error processing new admin conversation from /topic/admin/conversations/new: $e. Body: ${frame.body}');
        }
      },
    );
  }

  void sendMessageWebSocket(int conversationId, SendMessageRequestDTO payload) {
    if (_stompClient != null && _stompClient!.connected) {
      _stompClient?.send(
        destination: '/app/chat.sendMessage/$conversationId',
        body: jsonEncode(payload.toJson()),
      );
    } else {
      print('STOMP client not connected. Cannot send message.');
      // Optionally, implement a retry mechanism or queue messages.
    }
  }

  void joinConversation(int conversationId) {
    if (_stompClient != null && _stompClient!.connected) {
      _stompClient?.send(
        destination: '/app/chat.joinConversation/$conversationId',
        // Payload is null as per documentation
      );
    } else {
      print('STOMP client not connected. Cannot send join notification.');
    }
  }

  void disconnectWebSocket() {
    _stompClient?.deactivate();
    _stompClient = null;
  }

  void dispose() {
    disconnectWebSocket();
    _httpClient.close();
  }
}
