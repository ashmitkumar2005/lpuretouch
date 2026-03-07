import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/app_text_styles.dart';

class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  const ErrorRetryWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  static String friendlyMessage(String error) {
    if (error.contains('SocketException') || error.contains('Failed host lookup')) {
      return 'Internet connection problem.\nPlease check your data or Wi-Fi.';
    }
    if (error.contains('401') || error.contains('authenticated') || error.contains('Session Expired')) {
      return 'Session expired.\nPlease log in again.';
    }
    if (error.contains('500') || error.contains('server')) {
      return 'LPU server is temporarily down.\nPlease try again later.';
    }
    if (error.contains('timeout')) {
      return 'Connection timed out.\nTry again with a better signal.';
    }
    
    // If the error is a cleanly formatted message without tech jargon, pass it through.
    final lower = error.toLowerCase();
    if (!lower.contains('exception') && !lower.contains('dio') && !lower.contains('error:') && error.length < 100) {
      return error;
    }
    
    return 'Something went wrong.\nPlease check your connection and try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: AppTextStyles.title2.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary.withOpacity(0.5),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 160,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Try Again',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
