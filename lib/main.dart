import 'package:athleticcoach/presentation/screens/home_screen.dart';
import 'package:athleticcoach/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load();
  } catch (e) {
    print('Uyarı: .env dosyası yüklenemedi: $e');
    print('Uygulama varsayılan ayarlarla çalışacak.');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Athletic Coach',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
