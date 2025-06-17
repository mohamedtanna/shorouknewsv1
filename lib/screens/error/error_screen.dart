import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // For navigation
import '../../core/theme.dart'; // For consistent styling
import '../../widgets/section_app_bar.dart';

class ErrorScreen extends StatelessWidget {
  final String? errorMessage;
  final String? errorDetails; // Optional: for more detailed error info
  final VoidCallback? onRetry; // Optional: callback for a retry button
  final String? retryButtonText; // Optional: custom text for retry button
  final String? goHomeButtonText; // Optional: custom text for go home button

  const ErrorScreen({
    super.key,
    this.errorMessage,
    this.errorDetails,
    this.onRetry,
    this.retryButtonText = 'حاول مرة أخرى', // Default to Arabic
    this.goHomeButtonText = 'العودة للرئيسية', // Default to Arabic
  });

  @override
  Widget build(BuildContext context) {
    // Determine the message to display, defaulting to Arabic
    final displayErrorMessage = errorMessage ?? 'حدث خطأ غير متوقع.';
    final displayErrorDetails = errorDetails ?? 'يرجى المحاولة مرة أخرى لاحقاً أو الاتصال بالدعم الفني إذا استمرت المشكلة.';

    return Scaffold(
      appBar: SectionAppBar(
        title: const Text('خطأ'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Error Icon
              Icon(
                Icons.error_outline_rounded, // A clear error icon
                color: Colors.red[700], // Prominent error color
                size: 80,
              ),
              const SizedBox(height: 24),

              // Main Error Title
              Text(
                'عفواً!', // "Oops!" in Arabic
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor, // Use theme color
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Error Message
              Text(
                displayErrorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black87, // Readable text color
                    ),
              ),

              // Optional Error Details
              if (errorDetails != null && errorDetails!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  displayErrorDetails,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700], // Subdued color for details
                      ),
                ),
              ],
              const SizedBox(height: 32),

              // Retry Button (if onRetry is provided)
              if (onRetry != null) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(retryButtonText!),
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tertiaryColor, // Use theme color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Go Home Button
              OutlinedButton.icon(
                icon: const Icon(Icons.home_outlined),
                label: Text(goHomeButtonText!),
                onPressed: () {
                  context.go('/home'); // Navigate to home screen
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor, // Use theme color
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
