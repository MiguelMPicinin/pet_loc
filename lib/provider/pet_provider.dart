import 'package:flutter/material.dart';
import '../controller/petController.dart';

class PetProvider extends InheritedWidget {
  final PetController petController;

  const PetProvider({
    Key? key,
    required this.petController,
    required Widget child,
  }) : super(key: key, child: child);

  static PetController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PetProvider>()!.petController;
  }

  @override
  bool updateShouldNotify(PetProvider oldWidget) {
    return true;
  }
}