class CreateConversationRequestDTO {
  final String title;
  final String? initialMessage;

  CreateConversationRequestDTO({
    required this.title,
    this.initialMessage,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
    };
    if (initialMessage != null) {
      data['initialMessage'] = initialMessage;
    }
    return data;
  }
}
