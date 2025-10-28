import 'package:flutter/material.dart';

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFF2F2F2),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFDF9E1C),
  onPrimaryContainer: Color(0xFF2A1800),
  secondary: Color(0xFFFEE2B5),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFDF9E1C),
  onSecondaryContainer: Color(0xFF271900),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFF6E1B6),
  onTertiaryContainer: Color(0xFF001E2B),
  error: Color(0xFFBA1A1A),
  errorContainer: Color(0xFFFFDAD6),
  onError: Color(0xFFFFFFFF),
  onErrorContainer: Color(0xFF410002),
  surface: Color(0xFFF8FDFF),
  onSurface: Color(0xFF001F25),
  onSurfaceVariant: Color(0xFF504539),
  outline: Color(0xFF827568),
  onInverseSurface: Color(0xFFD6F6FF),
  inverseSurface: Color(0xFF00363F),
  inversePrimary: Color(0xFFFFB95A),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFF845400),
  outlineVariant: Color(0xFFD3C4B4),
  scrim: Color(0xFF000000),
  tertiary: Color(0xFFFFFFFF),
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF02374B),
  onPrimary: Color(0xFF462A00),
  primaryContainer: Color(0xFF073A4C),
  onPrimaryContainer: Color(0xFFFFDDB6),
  secondary: Color(0xFFF7BD48),
  onSecondary: Color(0xFF412D00),
  secondaryContainer: Color(0xFF5E4200),
  onSecondaryContainer: Color(0xFFFFDEA7),
  tertiary: Color(0xFF74D1FF),
  onTertiary: Color(0xFF003548),
  tertiaryContainer: Color(0xFF004D67),
  onTertiaryContainer: Color(0xFFC1E8FF),
  error: Color(0xFFFFB4AB),
  errorContainer: Color(0xFF93000A),
  onError: Color(0xFF690005),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF001F25),
  onSurface: Color(0xFFA6EEFF),
  onSurfaceVariant: Color(0xFFD3C4B4),
  outline: Color(0xFF9C8E80),
  onInverseSurface: Color(0xFF001F25),
  inverseSurface: Color(0xFFA6EEFF),
  inversePrimary: Color(0xFF845400),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFFFFB95A),
  outlineVariant: Color(0xFF504539),
  scrim: Color(0xFF000000),
);

InputDecorationTheme lightInputDecorationTheme() {
  return InputDecorationTheme(
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(100),
      borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(color: darkColorScheme.primary),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(
        color: lightColorScheme.primaryContainer,
        width: 2,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(
        color: lightColorScheme.primaryContainer.withOpacity(0.2),
        width: 1,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(5),
      borderSide: BorderSide(
        color: lightColorScheme.primaryContainer,
        width: 2,
      ),
    ),
  );
}
