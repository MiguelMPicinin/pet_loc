import 'package:flutter/material.dart';
import '../controller//desaparecidoController.dart';

class DesaparecidosProvider extends InheritedWidget {
  final DesaparecidosController desaparecidosController;

  const DesaparecidosProvider({
    Key? key,
    required this.desaparecidosController,
    required Widget child,
  }) : super(key: key, child: child);

  static DesaparecidosController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DesaparecidosProvider>()!.desaparecidosController;
  }

  @override
  bool updateShouldNotify(DesaparecidosProvider oldWidget) {
    return true;
  }
}   