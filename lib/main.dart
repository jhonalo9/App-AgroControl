import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es'); // necesario para mostrar fechas en español (ej: "03 Ago")
  runApp(const PapayasApp());
}

class PapayasApp extends StatelessWidget {
  const PapayasApp({super.key});

  @override
  Widget build(BuildContext context) {
    const verdeHoja = Color(0xFF2E7D32);
    const naranjaPapaya = Color(0xFFEF6C00);

    return MaterialApp(
      title: 'Papayas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: verdeHoja,
          primary: verdeHoja,
          secondary: naranjaPapaya,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: verdeHoja,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: verdeHoja,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.symmetric(vertical: 6),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}