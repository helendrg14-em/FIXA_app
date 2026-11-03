import 'package:flutter/material.dart';

/// Colores tomados del logo de FIXA.
class FixaColores {
  static const oscuro = Color(0xFF0D2C22);
  static const pino = Color(0xFF16483C);
  static const verde = Color(0xFF0F7A50);
  static const verdeClaro = Color(0xFFE4F2E6);
  static const naranja = Color(0xFFF79B2D);
  static const naranjaOscuro = Color(0xFFA85600);
  static const naranjaClaro = Color(0xFFFDF0DF);
  static const fondo = Color(0xFFF6F8F3);
  static const borde = Color(0xFFDDE5DA);
  static const textoSuave = Color(0xFF53665D);
}

ThemeData crearTema() {
  final bordeCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: FixaColores.borde),
  );

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: FixaColores.verde).copyWith(
      primary: FixaColores.verde,
      secondary: FixaColores.naranja,
      surface: Colors.white,
      onSurface: FixaColores.oscuro,
    ),
    scaffoldBackgroundColor: FixaColores.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: FixaColores.fondo,
      foregroundColor: FixaColores.oscuro,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: FixaColores.oscuro,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: bordeCampo,
      enabledBorder: bordeCampo,
      focusedBorder: bordeCampo.copyWith(
        borderSide: const BorderSide(color: FixaColores.verde, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: FixaColores.pino,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
