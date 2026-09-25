import 'package:flutter/material.dart';
import '../../../../application/assistant/ai_assistant_service.dart';
import '../../../../data/models/chat_message.dart';
import '../../../theme/colors/app_colors.dart';
import '../../../theme/text_styles.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  static const routeName = '/assistant';

  @override
  State<AiAssistantScreen> createState() => AiAssistantScreenState();
}

class AiAssistantScreenState extends State<AiAssistantScreen> {
  final service = AiAssistantService.instance;
  final inputController = TextEditingController();
  final scrollController = ScrollController();

  final List<ChatMessage> messages = [
    const ChatMessage(
      text: "Hi! I'm Flora, your Farm Products Assistant. Ask me about "
          "nutrition, storage, or what's in season — or tap a suggestion "
          "below.",
      fromUser: false,
    ),
  ];

  bool isThinking = false;

  @override
  void dispose() {
    inputController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isThinking) return;

    setState(() {
      messages.add(ChatMessage(text: trimmed, fromUser: true));
      isThinking = true;
    });
    inputController.clear();
    scrollToBottom();

    final reply = await service.ask(trimmed);

    if (!mounted) return;
    setState(() {
      messages.add(ChatMessage(text: reply, fromUser: false));
      isThinking = false;
    });
    scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Farm Products Assistant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length) {
                  return const TypingBubble();
                }
                return MessageBubble(message: messages[index]);
              },
            ),
          ),

        
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: AiAssistantService.suggestedQuestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final question = AiAssistantService.suggestedQuestions[index];
                return ActionChip(
                  label: Text(question, style: AppTextStyles.caption),
                  backgroundColor: AppColors.softGreen,
                  side: BorderSide.none,
                  onPressed: isThinking ? null : () => send(question),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: inputController,
                      onSubmitted: send,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: 'Ask about fruits, veggies, storage…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.mainGreen,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: isThinking ? null : () => send(inputController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;

    
    final bubbleColor = isUser
        ? AppColors.mainGreen
        : (message.isError ? AppColors.error.withOpacity(0.10) : AppColors.wheatGold.withOpacity(0.18));
    final textColor = isUser ? Colors.white : AppColors.textPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: AppTextStyles.bodyRegular.copyWith(color: textColor),
        ),
      ),
    );
  }
}

class TypingBubble extends StatelessWidget {
  const TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.earthySoil.withOpacity(0.18),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: SizedBox(
          width: 20,
          height: 12,
          child: Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.wheatGold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}