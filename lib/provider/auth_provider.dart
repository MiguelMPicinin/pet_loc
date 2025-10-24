import 'package:flutter/material.dart';
import '../controller//authController.dart';

class AuthProvider extends InheritedWidget {
  final AuthController authController;

  const AuthProvider({
    Key? key,
    required this.authController,
    required Widget child,
  }) : super(key: key, child: child);

  static AuthController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthProvider>()!.authController;
  }

  @override
  bool updateShouldNotify(AuthProvider oldWidget) {
    return true;
  }
}