import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/auth_controller.dart';
import 'theme.dart';
import 'views/login_screen.dart';

void main() {
  runApp(const AutoRentApp());
}

class AutoRentApp extends StatelessWidget {
  const AutoRentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: MaterialApp(
        title: 'AutoRent - Sistema de Alquiler de Vehículos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const LoginScreen(),
      ),
    );
  }
}
