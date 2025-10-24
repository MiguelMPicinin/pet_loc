import 'package:flutter/material.dart';
import '../controller/lojaController.dart';

class LojaProvider extends InheritedWidget {
  final LojaController lojaController;

  const LojaProvider({
    Key? key,
    required this.lojaController,
    required Widget child,
  }) : super(key: key, child: child);

  static LojaController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LojaProvider>()!.lojaController;
  }

  @override
  bool updateShouldNotify(LojaProvider oldWidget) {
    return true;
  }
}