import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/utils/tracking_service.dart';

/// A custom app bar with navigation buttons (back and home)
class AppNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title of the app bar
  final String title;
  
  /// Whether to show the back button
  final bool showBackButton;
  
  /// Whether to show the home button
  final bool showHomeButton;
  
  /// Additional actions to display in the app bar
  final List<Widget>? actions;
  
  /// Bottom widget for the app bar (e.g., TabBar)
  final PreferredSizeWidget? bottom;
  
  /// Custom back button action (optional)
  final VoidCallback? onBackPressed;
  
  /// Constructor for AppNavigationBar
  const AppNavigationBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.showHomeButton = true,
    this.actions,
    this.bottom,
    this.onBackPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    final trackingService = sl<TrackingService>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : null,
          shadows: isDarkMode ? [
            Shadow(
              blurRadius: 2,
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 1),
            ),
          ] : null,
        ),
      ),
      centerTitle: true,
      elevation: isDarkMode ? 4 : 0,
      scrolledUnderElevation: isDarkMode ? 8 : 4,
      shadowColor: isDarkMode ? Colors.black : Colors.black26,
      leading: showBackButton 
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode ? Colors.white : null,
                size: 24,
              ),
              tooltip: 'Back',
              onPressed: onBackPressed ?? () {
                trackingService.trackButtonClick('Back', screen: title);
                if (context.canPop()) {
                  // Use Future.microtask to avoid potential Navigator locks
                  Future.microtask(() {
                    if (context.mounted && context.canPop()) {
                      context.pop();
                      trackingService.trackNavigation('Back to previous screen');
                    }
                  });
                } else {
                  context.go(AppConstants.homeRoute);
                  trackingService.trackNavigation('Home (from back button)');
                }
              },
            )
          : null,
      actions: [
        if (showHomeButton)
          IconButton(
            icon: Icon(
              Icons.home,
              color: isDarkMode ? Colors.white : null,
              size: 24,
            ),
            tooltip: 'Home',
            onPressed: () {
              trackingService.trackButtonClick('Home', screen: title);
              context.go(AppConstants.homeRoute);
              trackingService.trackNavigation('Home');
            },
          ),
        if (actions != null) ...actions!,
      ],
      bottom: bottom,
    );
  }
  
  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0.0)
  );
} 