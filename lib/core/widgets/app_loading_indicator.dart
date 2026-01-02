import 'package:flutter/material.dart';

/// A standardized loading indicator widget for the app
class AppLoadingIndicator extends StatelessWidget {
  /// Optional message to display below the loading indicator
  final String? message;
  
  /// Constructor for AppLoadingIndicator
  const AppLoadingIndicator({
    super.key, 
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
} 