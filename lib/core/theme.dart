import 'package:flutter/material.dart';

/// Defines the color tokens used throughout the app.
const Color kPrimaryColor = Color(0xFF000000); // schwarz
const Color kAccentColor = Color(0xFFFFD700); // gold

/// Light theme for SalonManager.
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: kPrimaryColor,
  colorScheme: const ColorScheme.light(
    primary: kPrimaryColor,
    secondary: kAccentColor,
  ),
);

/// Dark theme for SalonManager.
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: kPrimaryColor,
  colorScheme: const ColorScheme.dark(
    primary: kPrimaryColor,
    secondary: kAccentColor,
  ),
);