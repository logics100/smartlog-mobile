import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme/smartlog_theme.dart';

void main() {
  runApp(const SmartLogApp());
}

class SmartLogApp extends StatelessWidget {
  const SmartLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartLog',
      theme: SmartLogTheme.light,
      home: const LoginScreen(),
    );
  }
}
