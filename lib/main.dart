import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NdaxApp());
}

class NdaxApp extends StatelessWidget {
  const NdaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    const cyan = Color(0xFF19D7E6);
    return MaterialApp(
      title: 'NDAX AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080D12),
        colorScheme: ColorScheme.fromSeed(
          seedColor: cyan,
          brightness: Brightness.dark,
          surface: const Color(0xFF101922),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF080D12),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF121E28),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
