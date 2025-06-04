import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart'; // Assuming you have this for form submission

// A model for contact form data
class ContactFormData {
  final String name;
  final String email;
  final String subject;
  final String message;

  ContactFormData({
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
    };
  }
}

class ContactModule {
  final ApiService _apiService = ApiService();

  // Static contact information (replace with actual data)
  static const String contactEmail = 'contact@shorouknews.com';
  static const String phoneNumber = '+20 2 27981600'; // Example phone
  static const String address =
      '12th floor, Shorouk Building, 8 Talaat Harb St., Downtown, Cairo, Egypt';
  static const String websiteUrl = 'https://www.shorouknews.com';

  // Social media links
  static const Map<String, String> socialLinks = {
    'facebook': 'https://www.facebook.com/shorouknews',
    'twitter': 'https://twitter.com/shorouk_news',
    'youtube': 'https://www.youtube.com/user/ShoroukNews',
    'instagram': 'https://www.instagram.com/shorouknews',
  };

  /// Attempts to launch the given URL.
  /// Throws an exception if the URL can't be launched.
  Future<void> launchUrlUtil(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
      throw 'Could not launch $url';
    }
  }

  /// Opens the default email client with pre-filled information.
  Future<void> launchEmail({
    String email = contactEmail,
    String subject = 'Inquiry from Shorouk News App',
    String body = '',
  }) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    await launchUrlUtil(emailLaunchUri.toString());
  }

  /// Submits the contact form data to the backend.
  /// Returns true if successful, false otherwise.
  Future<bool> submitContactForm(ContactFormData formData) async {
    try {
      // In a real app, you would send this to your backend.
      // Using the ApiService as an example.
      // Replace 'contact/submit' with your actual endpoint.
      final success = await _apiService.submitContactForm(
        name: formData.name,
        email: formData.email,
        subject: formData.subject,
        message: formData.message,
      );
      // Simulate API call
      // await Future.delayed(const Duration(seconds: 1));
      // debugPrint('Form submitted: ${formData.toJson()}');
      // const bool success = true; // Simulate success

      if (success) {
        debugPrint('Contact form submitted successfully.');
        return true;
      } else {
        debugPrint('Contact form submission failed.');
        return false;
      }
    } catch (e) {
      debugPrint('Error submitting contact form: $e');
      return false;
    }
  }
}
