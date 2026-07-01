import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'ui/views/login_view.dart';
import 'ui/widgets/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DatabaseService()),
      ],
      child: const AgriCoreApp(),
    ),
  );
}

class AgriCoreApp extends StatelessWidget {
  const AgriCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriCore Operations Portal',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark, // Default to dark mode for a premium dark console look
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF10B981), // Emerald green
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Dark slate
        cardColor: const Color(0xFF1E293B), // Card slate
        dividerColor: const Color(0xFF334155),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          secondary: Color(0xFF3B82F6), // Blue accent
          surface: Color(0xFF1E293B),
          background: const Color(0xFF0F172A),
          error: Color(0xFFEF4444),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFFF1F5F9),
          onBackground: Color(0xFFF1F5F9),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
          bodyLarge: GoogleFonts.outfit(color: const Color(0xFFE2E8F0)),
          bodyMedium: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFF1F5F9)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E293B),
          labelStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
          hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
        ),
      ),
      home: Consumer<AuthService>(
        builder: (context, authService, child) {
          if (authService.isAuthenticated) {
            return const AppShell();
          }
          return const LoginView();
        },
      ),
    );
  }
}
