//import 'package:app_inventario_flutter/services/backup_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'config/demo_config.dart';
import 'database/database_helper.dart';
import 'screens/demo_expirada_page.dart';
import 'screens/main_layout.dart';
import 'services/demo_service.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Inicializar window_manager
  await windowManager.ensureInitialized();

  // 🔥 Inicializar SQLite para Windows
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // 🔥 Inicializar la demo (guarda fecha si es la primera vez)
  if (DemoConfig.isDemo) {
    await DemoService.inicializar();
  }

  // 🔥 Inicializar la base de datos
  await DatabaseHelper().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventario Pro',
      locale: const Locale('es', 'AR'),
      supportedLocales: const [
        Locale('es', 'AR'),
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // 🔥 Verificar el estado de la demo
      home: _decidirPantallaInicial(),
    );
  }

  /// Decide si mostrar la pantalla bloqueada o la app
  Widget _decidirPantallaInicial() {
    // Si no es demo → app normal
    if (!DemoConfig.isDemo) {
      return const MainLayout();
    }

    // Si es demo → verificar estado
    return FutureBuilder<DemoStatus>(
      future: DemoService.obtenerEstado(),
      builder: (context, snapshot) {
        // Mientras carga → splash simple
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        // Si hay error → app normal (por las dudas)
        if (snapshot.hasError || !snapshot.hasData) {
          return const MainLayout();
        }

        // Si expiró → pantalla bloqueada
        if (snapshot.data!.expirado) {
          return const DemoExpiradaPage();
        }

        // Si no expiró → app normal
        return const MainLayout();
      },
    );
  }
}

/// Pantalla simple mientras se verifica el estado de la demo
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade800,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'Inventario Pro',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}