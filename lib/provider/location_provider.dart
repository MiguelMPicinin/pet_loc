import 'package:flutter/material.dart';
import '../controller/locationController.dart';

class LocationProvider extends InheritedWidget {
  final LocationController locationController;

  const LocationProvider({
    Key? key,
    required this.locationController,
    required Widget child,
  }) : super(key: key, child: child);

  static LocationController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocationProvider>()!.locationController;
  }

  @override
  bool updateShouldNotify(LocationProvider oldWidget) {
    return true;
  }
}