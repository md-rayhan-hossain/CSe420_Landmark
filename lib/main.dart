import 'package:flutter/material.dart';
import 'package:geo_entities_app/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final bool enableMap;
  final bool loadOnStart;

  const MyApp({
    super.key,
    this.enableMap = true,
    this.loadOnStart = true,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Geo-Tagged Landmarks',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAF9),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF10201D),
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE0E7E5)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: SmartLandmarksHome(
        enableMap: enableMap,
        loadOnStart: loadOnStart,
      ),
    );
  }
}
