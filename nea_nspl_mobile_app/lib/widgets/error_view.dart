import 'package:flutter/material.dart';

import '../config/theme.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool showSupportOption;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.showSupportOption = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: AppTheme.headingStyle.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTheme.bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
            if (showSupportOption) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // In a real app, this would open a support contact page or form
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact support at support@nspl.com'),
                    ),
                  );
                },
                child: const Text('Contact Support'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
