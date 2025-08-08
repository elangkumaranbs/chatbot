import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/chat_provider.dart';
import 'screens/simple_chat_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ChatProvider(),
      child: MaterialApp(
        title: 'Gemini Chat App',
        theme: ThemeData(
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF1E88E5), // Beautiful blue primary
            secondary: const Color(0xFF42A5F5), // Lighter blue secondary
            tertiary: const Color(0xFF0D47A1), // Darker blue tertiary
            surface: const Color(0xFF1A1A1A), // Dark surface color
            background: const Color(0xFF0F0F0F), // Deep dark background
            onSurface: Colors.white, // White text on surface
            onBackground: Colors.white, // White text on background
            surfaceVariant: const Color(0xFF2A2A2A), // For cards and containers
            onSurfaceVariant: const Color(0xFFE3F2FD), // Light blue text
          ),
          scaffoldBackgroundColor: const Color(
            0xFF0F0F0F,
          ), // Deep dark background
          cardColor: const Color(0xFF1A1A1A), // Card background
          useMaterial3: true,
          fontFamily: 'Inter', // Using Inter font
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0xFF1E88E5).withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            elevation: 12,
          ),
        ),
        darkTheme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF1E88E5), // Beautiful blue primary
            secondary: const Color(0xFF42A5F5), // Lighter blue secondary
            tertiary: const Color(0xFF0D47A1), // Darker blue tertiary
            surface: const Color(0xFF1A1A1A), // Dark surface color
            background: const Color(0xFF0F0F0F), // Deep dark background
            surfaceVariant: const Color(0xFF2A2A2A), // For cards and containers
          ),
          scaffoldBackgroundColor: const Color(0xFF0F0F0F),
          cardColor: const Color(0xFF1A1A1A),
        ),
        themeMode: ThemeMode.dark, // Force dark theme
        home: const ChatScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
