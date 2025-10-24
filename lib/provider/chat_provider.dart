import 'package:flutter/material.dart';
import '../controller/chatController.dart';

class ChatProvider extends InheritedWidget {
  final ChatController chatController;

  const ChatProvider({
    Key? key,
    required this.chatController,
    required Widget child,
  }) : super(key: key, child: child);

  static ChatController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ChatProvider>()!.chatController;
  }

  @override
  bool updateShouldNotify(ChatProvider oldWidget) {
    return true;
  }
}