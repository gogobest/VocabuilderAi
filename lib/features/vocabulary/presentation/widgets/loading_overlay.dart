import 'package:flutter/material.dart';

/// A loading overlay widget that displays a centered CircularProgressIndicator
/// on a semi-transparent background
class LoadingOverlay extends StatelessWidget {
  /// Whether to show the loading indicator
  final bool isLoading;
  
  /// The child widget to display
  final Widget child;

  /// Creates a loading overlay
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 