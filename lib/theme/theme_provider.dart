import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeKey = 'theme_mode';

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
          default:
            _themeMode = ThemeMode.system;
            break;
        }
    notifyListeners();
      }
    } catch (e) {
      print('Error loading saved theme: $e');
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, isDark ? 'dark' : 'light');
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  Future<void> setSystemTheme() async {
    _themeMode = ThemeMode.system;
    notifyListeners();
    
    try {
    final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, 'system');
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  // Responsive theme data that adapts to screen size
  ThemeData getLightTheme(Size screenSize) {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      useMaterial3: true,
      
      // Responsive text themes
      textTheme: _getResponsiveTextTheme(screenSize, Brightness.light),
      
      // Responsive component themes
      elevatedButtonTheme: _getResponsiveElevatedButtonTheme(screenSize),
      outlinedButtonTheme: _getResponsiveOutlinedButtonTheme(screenSize),
      textButtonTheme: _getResponsiveTextButtonTheme(screenSize),
      inputDecorationTheme: _getResponsiveInputDecorationTheme(screenSize),
      cardTheme: _getResponsiveCardTheme(screenSize),
      
      // Responsive spacing
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  ThemeData getDarkTheme(Size screenSize) {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      useMaterial3: true,
      
      // Responsive text themes
      textTheme: _getResponsiveTextTheme(screenSize, Brightness.dark),
      
      // Responsive component themes
      elevatedButtonTheme: _getResponsiveElevatedButtonTheme(screenSize),
      outlinedButtonTheme: _getResponsiveOutlinedButtonTheme(screenSize),
      textButtonTheme: _getResponsiveTextButtonTheme(screenSize),
      inputDecorationTheme: _getResponsiveInputDecorationTheme(screenSize),
      cardTheme: _getResponsiveCardTheme(screenSize),
      
      // Responsive spacing
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // Responsive text theme based on screen size
  TextTheme _getResponsiveTextTheme(Size screenSize, Brightness brightness) {
    final baseFontSize = screenSize.width * 0.04; // 4% of screen width
    
    return TextTheme(
      displayLarge: TextStyle(fontSize: baseFontSize * 2.5, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(fontSize: baseFontSize * 2.0, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(fontSize: baseFontSize * 1.75, fontWeight: FontWeight.bold),
      
      headlineLarge: TextStyle(fontSize: baseFontSize * 1.5, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontSize: baseFontSize * 1.25, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(fontSize: baseFontSize * 1.1, fontWeight: FontWeight.bold),
      
      titleLarge: TextStyle(fontSize: baseFontSize * 1.0, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: baseFontSize * 0.9, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(fontSize: baseFontSize * 0.8, fontWeight: FontWeight.w600),
      
      bodyLarge: TextStyle(fontSize: baseFontSize * 1.0),
      bodyMedium: TextStyle(fontSize: baseFontSize * 0.9),
      bodySmall: TextStyle(fontSize: baseFontSize * 0.8),
      
      labelLarge: TextStyle(fontSize: baseFontSize * 0.9, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: baseFontSize * 0.8, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: baseFontSize * 0.7, fontWeight: FontWeight.w500),
    );
  }

  // Responsive elevated button theme
  ElevatedButtonThemeData _getResponsiveElevatedButtonTheme(Size screenSize) {
    final padding = screenSize.width * 0.04;
    final height = screenSize.height * 0.06;
    
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: height * 0.3,
        ),
        minimumSize: Size(0, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenSize.width * 0.02),
        ),
      ),
    );
  }

  // Responsive outlined button theme
  OutlinedButtonThemeData _getResponsiveOutlinedButtonTheme(Size screenSize) {
    final padding = screenSize.width * 0.04;
    final height = screenSize.height * 0.06;
    
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: height * 0.3,
        ),
        minimumSize: Size(0, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenSize.width * 0.02),
        ),
      ),
    );
  }

  // Responsive text button theme
  TextButtonThemeData _getResponsiveTextButtonTheme(Size screenSize) {
    final padding = screenSize.width * 0.02;
    final height = screenSize.height * 0.05;
    
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: height * 0.3,
        ),
        minimumSize: Size(0, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenSize.width * 0.01),
        ),
      ),
    );
  }

  // Responsive input decoration theme
  InputDecorationTheme _getResponsiveInputDecorationTheme(Size screenSize) {
    final padding = screenSize.width * 0.04;
    final borderRadius = screenSize.width * 0.02;
    
    return InputDecorationTheme(
      contentPadding: EdgeInsets.symmetric(
        horizontal: padding * 0.5,
        vertical: padding * 0.3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  // Responsive card theme
  CardThemeData _getResponsiveCardTheme(Size screenSize) {
    final borderRadius = screenSize.width * 0.03;
    final elevation = 2.0;
    
    return CardThemeData(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      margin: EdgeInsets.all(screenSize.width * 0.02),
    );
  }
}
