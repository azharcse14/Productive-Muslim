import 'package:flutter/material.dart';

void main() {
  runApp(const QalbeeApp());
}

/// Root widget. Phase 1 replaces the placeholder home with the themed
/// go_router shell (see docs/QALBEE_IMPLEMENTATION_PLAN.md).
final class QalbeeApp extends StatelessWidget {
  const QalbeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qalbee',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF15564D)),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF79C7B6),
        brightness: Brightness.dark,
      ),
      home: const Scaffold(
        body: Center(child: Text('Qalbee')),
      ),
    );
  }
}
