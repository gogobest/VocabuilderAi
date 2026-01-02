import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utility to handle app icon functionality
class AppIcon {
  // Private constructor to prevent instantiation
  AppIcon._();
  
  /// Generate a custom app icon instead of the Flutter logo
  static Future<void> setupAppIcon() async {
    // For a proper implementation, we use the flutter_launcher_icons package
    // The actual icons are configured in the pubspec.yaml file
  }
  
  /// Creates a custom logo widget for use within the app
  static Widget buildLogoWidget({double size = 120}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(size / 5),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Padding(
            padding: EdgeInsets.all(size / 6),
            child: Text(
              'V',
              style: TextStyle(
                color: Colors.white,
                fontSize: size / 1.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 