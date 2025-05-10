class SendMessageRequestDTO {
  final int conversationId;
  final String? content;
  final String? imageUrl;

  SendMessageRequestDTO({
    required this.conversationId,
    this.content,
    this.imageUrl,
  }) : assert(content != null || imageUrl != null, 'Either content or imageUrl must be provided.');

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['conversationId'] = conversationId;
    if (content != null) {
      data['content'] = content;
    }
    if (imageUrl != null) {
      data['imageUrl'] = imageUrl;
    }
    return data;
  }
}
