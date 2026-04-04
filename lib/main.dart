import 'package:flutter/material.dart';

import 'View/auth/login_page.dart';

void main() {
  runApp(const BillingApp());
}

class BillingApp extends StatelessWidget {
  const BillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Billing ERP',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0A2540),
        scaffoldBackgroundColor: const Color(0xFFEFF3F6),
      ),
      home: const LoginPage(),
    );
  }
}
