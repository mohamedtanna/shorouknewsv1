import 'package:flutter/material.dart';

import '../../core/theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Builder(
          builder: (context) {
            final textTheme = Theme.of(context).textTheme;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Terms of Service',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Please read these Terms of Service carefully before using our application.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16.0),
                Text(
                  '1. Acceptance of Terms',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'By accessing or using the application, you agree to be bound by these Terms of Service and all terms incorporated by reference. If you do not agree to all of these terms, do not use the application.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16.0),
                Text(
                  '2. Changes to Terms',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'We reserve the right to change or modify these Terms of Service at any time and in our sole discretion. If we make changes, we will provide notice of such changes, such as by sending an email notification, providing notice through the application, or updating the "Last Updated" date at the top of these Terms of Service. Your continued use of the application will confirm your acceptance of the revised Terms of Service. We encourage you to frequently review the Terms of Service to ensure you understand the terms and conditions that apply to your use of the application.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16.0),
                Text(
                  '3. Privacy Policy',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Please refer to our Privacy Policy for information about how we collect, use, and disclose information about our users.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 16.0),
                Text(
                  '4. Content',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'All content on the application, including but not limited to text, graphics, images, and software, is the property of [Your Company Name] or its licensors and is protected by copyright and other intellectual property laws.',
                  style: textTheme.bodyMedium,
                ),
                // Add more terms as needed
              ],
            );
          },
        ),
      ),
    );
  }
}
