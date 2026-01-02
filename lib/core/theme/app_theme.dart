import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';

/// App theme including light and dark mode
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();
  
  /// Primary color of the app
  static const Color _primaryColor = Color(0xFF6750A4);
  
  /// Secondary color of the app
  static const Color _secondaryColor = Color(0xFF625B71);
  
  /// Tertiary color of the app
  static const Color _tertiaryColor = Color(0xFF7D5260);
  
  /// Dark theme primary color - more vibrant for better visibility
  static const Color _darkPrimaryColor = Color(0xFF9373FF);
  
  /// Dark theme background color - true black looks better on OLED screens
  static const Color _darkBackgroundColor = Color(0xFF121212);
  
  /// Dark theme surface color - slightly lighter than background
  static const Color _darkSurfaceColor = Color(0xFF1E1E1E);
  
  /// Dark theme card color - lighter than surface for contrast
  static const Color _darkCardColor = Color(0xFF252525);
  
  /// Get the text theme using either local fonts or Google Fonts
  static TextTheme _getTextTheme(TextTheme baseTheme) {
    // For web, use local fonts defined in pubspec.yaml
    if (kIsWeb) {
      return baseTheme.copyWith(
        displayLarge: baseTheme.displayLarge?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        displayMedium: baseTheme.displayMedium?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        displaySmall: baseTheme.displaySmall?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        headlineLarge: baseTheme.headlineLarge?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        headlineMedium: baseTheme.headlineMedium?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        headlineSmall: baseTheme.headlineSmall?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        titleLarge: baseTheme.titleLarge?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        titleMedium: baseTheme.titleMedium?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        titleSmall: baseTheme.titleSmall?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        bodyLarge: baseTheme.bodyLarge?.copyWith(fontFamily: 'Poppins'),
        bodyMedium: baseTheme.bodyMedium?.copyWith(fontFamily: 'Poppins'),
        bodySmall: baseTheme.bodySmall?.copyWith(fontFamily: 'Poppins'),
        labelLarge: baseTheme.labelLarge?.copyWith(fontFamily: 'Poppins', fontWeight: FontWeight.w500),
        labelMedium: baseTheme.labelMedium?.copyWith(fontFamily: 'Poppins'),
        labelSmall: baseTheme.labelSmall?.copyWith(fontFamily: 'Poppins')
      );
    }
    
    // For mobile, we can still use GoogleFonts
    return GoogleFonts.poppinsTextTheme(baseTheme);
  }
  
  /// Light theme for the app
  static ThemeData get lightTheme {
    final textTheme = _getTextTheme(ThemeData.light().textTheme);
    
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: TextStyle(
            inherit: true,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        space: 24,
        thickness: 1,
      ),
    );
  }
  
  /// Dark theme for the app
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final TextTheme darkTextTheme = kIsWeb
      ? _getTextTheme(baseTextTheme).copyWith(
          // Apply web-specific text styles
          headlineLarge: baseTextTheme.headlineLarge?.copyWith(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: baseTextTheme.headlineMedium?.copyWith(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
          bodySmall: baseTextTheme.bodySmall?.copyWith(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
          labelLarge: baseTextTheme.labelLarge?.copyWith(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        )
      : GoogleFonts.poppinsTextTheme(baseTextTheme).copyWith(
          // Make headings more prominent with better contrast
          headlineLarge: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          // Make body text slightly larger and with better contrast
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
          bodySmall: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
          // Labels for buttons and other UI elements
          labelLarge: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        );
    
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: _darkPrimaryColor,
        onPrimary: Colors.white,
        primaryContainer: _darkPrimaryColor.withOpacity(0.2),
        onPrimaryContainer: _darkPrimaryColor,
        secondary: _secondaryColor.withOpacity(0.8),
        onSecondary: Colors.white,
        secondaryContainer: _secondaryColor.withOpacity(0.2),
        onSecondaryContainer: Colors.white.withOpacity(0.9),
        tertiary: _tertiaryColor.withOpacity(0.8),
        onTertiary: Colors.white,
        tertiaryContainer: _tertiaryColor.withOpacity(0.2),
        onTertiaryContainer: Colors.white.withOpacity(0.9),
        error: Colors.redAccent,
        onError: Colors.white,
        errorContainer: Colors.redAccent.withOpacity(0.2),
        onErrorContainer: Colors.white,
        background: _darkBackgroundColor,
        onBackground: Colors.white.withOpacity(0.9),
        surface: _darkSurfaceColor,
        onSurface: Colors.white.withOpacity(0.9),
        surfaceVariant: _darkCardColor,
        onSurfaceVariant: Colors.white.withOpacity(0.8),
        outline: Colors.grey[700]!,
        shadow: Colors.black,
        inverseSurface: Colors.white.withOpacity(0.1),
        onInverseSurface: Colors.white,
        inversePrimary: _primaryColor.withOpacity(0.8),
        surfaceTint: _darkPrimaryColor.withOpacity(0.1),
      ),
      scaffoldBackgroundColor: _darkBackgroundColor,
      cardColor: _darkCardColor,
      dialogBackgroundColor: _darkSurfaceColor,
      textTheme: darkTextTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _darkSurfaceColor,
        foregroundColor: Colors.white,
        titleTextStyle: darkTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: _darkPrimaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: _darkPrimaryColor.withOpacity(0.4),
          textStyle: TextStyle(
            inherit: true,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: _darkPrimaryColor, width: 1.5),
          textStyle: darkTextTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: darkTextTheme.labelLarge,
        ),
      ),
      cardTheme: CardTheme(
        color: _darkCardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        shadowColor: Colors.black.withOpacity(0.4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _darkPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkCardColor,
        contentTextStyle: darkTextTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurfaceColor,
        disabledColor: Colors.grey[800],
        selectedColor: _darkPrimaryColor.withOpacity(0.3),
        secondarySelectedColor: _darkPrimaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: DividerThemeData(
        space: 24,
        thickness: 1,
        color: Colors.grey[800],
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _darkSurfaceColor,
        indicatorColor: _darkPrimaryColor.withOpacity(0.3),
        labelTextStyle: MaterialStateProperty.all(
          darkTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        iconTheme: MaterialStateProperty.resolveWith<IconThemeData?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return IconThemeData(color: _darkPrimaryColor);
            }
            return IconThemeData(color: Colors.white.withOpacity(0.8));
          },
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkSurfaceColor,
        selectedItemColor: _darkPrimaryColor,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _darkPrimaryColor,
        linearTrackColor: _darkPrimaryColor.withOpacity(0.2),
        circularTrackColor: _darkPrimaryColor.withOpacity(0.2),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        highlightElevation: 12,
        enableFeedback: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return _darkPrimaryColor;
          }
          return Colors.grey[400];
        }),
        trackColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return _darkPrimaryColor.withOpacity(0.5);
          }
          return Colors.grey[700];
        }),
      ),
    );
  }
} 