class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.fromUser,
    this.isError = false,
  });

  final String text;
  final bool fromUser;

  final bool isError;
}