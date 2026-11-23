import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FixaColores {
  static const bosque = Color(0xFF063E2A);
  static const bosque2 = Color(0xFF124531);
  static const hojaOscura = Color(0xFF006C46);
  static const hojaViva = Color(0xFF168359);
  static const lima = Color(0xFFD8FBE9);
  static const sol = Color(0xFFFFAB11);
  static const solClaro = Color(0xFFFFE7A1);
  static const naranjaSuave = Color(0xFFFFEAE0);
  static const naranjaTexto = Color(0xFF9A4208);
  static const blanco = Color(0xFFFEFEFF);
  static const papel = Color(0xFFEDF2EE);
  static const menta = Color(0xFFE5F1E9);
  static const menta2 = Color(0xFFDDEADA);
  static const tinta = Color(0xFF111B2D);
  static const tinta2 = Color(0xFF34465D);
  static const linea = Color(0xFFC9D5E3);
  static const azul = Color(0xFF1C4BE8);
  static const azulSuave = Color(0xFFDBE8FF);
  static const error = Color(0xFFB42318);

  static const sistema = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
}

TextStyle tituloFixa(double size, {Color color = FixaColores.tinta}) =>
    TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.35,
        color: color);

ThemeData crearTema() {
  final texto = ThemeData.light().textTheme.apply(
        bodyColor: FixaColores.tinta,
        displayColor: FixaColores.tinta,
      );
  final bordeCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: FixaColores.linea),
  );
  final formaBoton =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  const textoBoton = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);

  return ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(seedColor: FixaColores.hojaOscura).copyWith(
      primary: FixaColores.hojaOscura,
      onPrimary: FixaColores.blanco,
      surface: FixaColores.blanco,
      onSurface: FixaColores.tinta,
      error: FixaColores.error,
    ),
    scaffoldBackgroundColor: FixaColores.papel,
    textTheme: texto.copyWith(
      bodyLarge:
          const TextStyle(fontSize: 16, height: 1.45, color: FixaColores.tinta),
      bodyMedium:
          const TextStyle(fontSize: 15, height: 1.45, color: FixaColores.tinta),
      bodySmall:
          const TextStyle(fontSize: 13, height: 1.4, color: FixaColores.tinta2),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: FixaColores.papel,
      foregroundColor: FixaColores.tinta,
      scrolledUnderElevation: 0,
      systemOverlayStyle: FixaColores.sistema,
      titleTextStyle: tituloFixa(22),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FixaColores.blanco,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      hintStyle: const TextStyle(color: FixaColores.tinta2),
      prefixIconColor: FixaColores.tinta2,
      suffixIconColor: FixaColores.tinta2,
      border: bordeCampo,
      enabledBorder: bordeCampo,
      focusedBorder: bordeCampo.copyWith(
          borderSide:
              const BorderSide(color: FixaColores.hojaOscura, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FixaColores.bosque,
        foregroundColor: FixaColores.blanco,
        disabledBackgroundColor: FixaColores.linea,
        disabledForegroundColor: FixaColores.tinta2,
        minimumSize: const Size.fromHeight(54),
        shape: formaBoton,
        textStyle: textoBoton,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FixaColores.hojaOscura,
        backgroundColor: FixaColores.blanco,
        minimumSize: const Size.fromHeight(46),
        side: const BorderSide(color: FixaColores.linea),
        shape: formaBoton,
        textStyle: textoBoton,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
          foregroundColor: FixaColores.hojaOscura, textStyle: textoBoton),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: FixaColores.bosque2,
    ),
  );
}
