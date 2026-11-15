import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colores de FIXA: los mismos del portal y del panel (public/css/fixa-portal.css).
class FixaColores {
  static const bosque = Color(0xFF0B2418);
  static const bosque2 = Color(0xFF12382A);
  static const hoja = Color(0xFF1F7D47);
  static const hojaOscura = Color(0xFF17643A);
  static const hojaViva = Color(0xFF2E9A58);
  static const brote = Color(0xFF9CCC3C);
  static const lima = Color(0xFFC9E46E);
  static const sol = Color(0xFFF4B223);
  static const solClaro = Color(0xFFFFD877);
  static const naranja = Color(0xFFEC7B12);
  static const naranjaSuave = Color(0xFFFFF1DF);
  static const naranjaTexto = Color(0xFF9A4208);
  static const blanco = Color(0xFFFFFFFF);
  static const papel = Color(0xFFF5F7F2);
  static const papel2 = Color(0xFFE9EEE5);
  static const menta = Color(0xFFEDF5E8);
  static const menta2 = Color(0xFFDCEBD3);
  static const tinta = Color(0xFF0F2E24);
  static const tinta2 = Color(0xFF4A5D48);
  static const linea = Color(0xFFD5DDD0);
  static const error = Color(0xFFB42318);
}

/// Las pruebas lo apagan: Google Fonts descarga las fuentes y en las pruebas no hay red.
bool usarFuentesDeMarca = true;

/// Títulos en Bricolage Grotesque y textos en Atkinson Hyperlegible, pensada para leer
/// fácil con poca visión (RNF09).
TextStyle tituloFixa(double size, {Color color = FixaColores.bosque}) {
  final estilo = TextStyle(
      fontSize: size, fontWeight: FontWeight.w800, letterSpacing: -size * 0.02, height: 1.08, color: color);
  return usarFuentesDeMarca ? GoogleFonts.bricolageGrotesque(textStyle: estilo) : estilo;
}

TextStyle _texto(double size, {FontWeight peso = FontWeight.w400, Color? color}) {
  final estilo = TextStyle(fontSize: size, fontWeight: peso, color: color);
  return usarFuentesDeMarca ? GoogleFonts.atkinsonHyperlegible(textStyle: estilo) : estilo;
}

ThemeData crearTema() {
  final texto = ThemeData.light().textTheme.apply(
    fontFamily: _texto(16).fontFamily,
    bodyColor: FixaColores.tinta,
    displayColor: FixaColores.tinta,
  );
  final bordeCampo = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: FixaColores.linea, width: 1.5),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: FixaColores.hoja).copyWith(
      primary: FixaColores.hojaOscura,
      onPrimary: FixaColores.blanco,
      secondary: FixaColores.sol,
      onSecondary: FixaColores.bosque,
      surface: FixaColores.blanco,
      onSurface: FixaColores.tinta,
      error: FixaColores.error,
    ),
    scaffoldBackgroundColor: FixaColores.papel,
    textTheme: texto.copyWith(
      bodyLarge: texto.bodyLarge?.copyWith(fontSize: 17, height: 1.45),
      bodyMedium: texto.bodyMedium?.copyWith(fontSize: 16, height: 1.45),
      bodySmall: texto.bodySmall?.copyWith(fontSize: 14, color: FixaColores.tinta2),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: FixaColores.papel,
      foregroundColor: FixaColores.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: tituloFixa(20, color: FixaColores.tinta).copyWith(fontWeight: FontWeight.w700, letterSpacing: 0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FixaColores.blanco,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: FixaColores.tinta2),
      border: bordeCampo,
      enabledBorder: bordeCampo,
      focusedBorder: bordeCampo.copyWith(
        borderSide: const BorderSide(color: FixaColores.hojaOscura, width: 2.5),
      ),
      errorBorder: bordeCampo.copyWith(borderSide: const BorderSide(color: FixaColores.error, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FixaColores.hojaOscura,
        foregroundColor: FixaColores.blanco,
        disabledBackgroundColor: FixaColores.linea,
        disabledForegroundColor: FixaColores.tinta2,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: _texto(18, peso: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: FixaColores.hojaOscura,
        backgroundColor: FixaColores.blanco,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: FixaColores.hojaViva, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: _texto(17, peso: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: FixaColores.bosque2,
      contentTextStyle: _texto(16, color: FixaColores.blanco),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
