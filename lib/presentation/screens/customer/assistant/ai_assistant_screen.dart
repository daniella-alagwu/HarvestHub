import 'package:flutter/material.dart';
import '../../../../application/assistant/ai_assistant_service.dart';
import '../../../../data/models/chat_message.dart';
import '../../../theme/colors/app_colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/typing_indicator.dart';

const _floraAvatarAsset = 'assets/images/mascot/flora_avatar_96.png';
const _floraHeaderAsset = 'assets/images/mascot/flora_avatar_160.png';

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
      text: "Hi! I'm Flora, your Farm Products Assistant 🌱. Ask me about "
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
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0), 
          child: Row(
            children: [
              const CircleAvatar(
                radius: 19,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage(_floraHeaderAsset),
              ),
              const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
              const Text('Flora', style: TextStyle(fontWeight: FontWeight.w700)),
              Text(
                'Farm Products Assistant',
                style: TextStyle(
                  fontSize: 11.5, 
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.softGreen.withOpacity(0.55), AppColors.background],
            stops: const [0.0, 0.25],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
                itemCount: messages.length + (isThinking ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return const _AssistantTypingBubble();
                  }
                  return _MessageBubble(message: messages[index]);
                },
              ),
            ),

           
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: AiAssistantService.suggestedQuestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final question = AiAssistantService.suggestedQuestions[index];
                  final isAutumn = index.isOdd;
                  final accent = isAutumn ? AppColors.autumnRust : AppColors.mainGreen;
                  final icon = const [
                    Icons.local_florist_outlined,
                    Icons.kitchen_outlined,
                    Icons.calendar_month_outlined,
                    Icons.eco_outlined,
                    Icons.restaurant_outlined,
                  ][index % 5];

                  return _SuggestionChip(
                    label: question,
                    icon: icon,
                    accent: accent,
                    onTap: isThinking ? null : () => send(question),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: _ChatInputBar(
                  controller: inputController,
                  enabled: !isThinking,
                  onSend: send,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;

    final bubbleColor = isUser
        ? AppColors.mainGreen
        : (message.isError ? AppColors.error.withOpacity(0.10) : Colors.white);
    final textColor = isUser ? Colors.white : AppColors.textPrimary;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(message.text, style: AppTextStyles.bodyRegular.copyWith(color: textColor)),
    );

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(alignment: Alignment.centerRight, child: bubble),
      );
    }

    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 14, backgroundImage: AssetImage(_floraAvatarAsset)),
          const SizedBox(width: 8),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _AssistantTypingBubble extends StatelessWidget {
  const _AssistantTypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(radius: 14, backgroundImage: AssetImage(_floraAvatarAsset)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: TypingIndicator(dotColor: AppColors.mainGreen.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withOpacity(0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}


//input area
class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({required this.controller, required this.enabled, required this.onSend});

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onSubmitted: onSend,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                hintText: 'Ask about fruits, veggies, storage…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.mainGreen, AppColors.deepGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: enabled ? () => onSend(controller.text) : null,
            ),
          ),
        ],
      ),
    );
  }
}