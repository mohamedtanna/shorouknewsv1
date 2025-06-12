import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// For launching URLs

import '../../core/theme.dart';
// import '../../widgets/ad_banner.dart';
import 'contact_module.dart'; // Import the module

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;
  final ContactModule _contactModule = ContactModule();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final formData = ContactFormData(
        name: _nameController.text,
        email: _emailController.text,
        subject: _subjectController.text,
        message: _messageController.text,
      );

      try {
        final success = await _contactModule.submitContactForm(formData);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إرسال رسالتك بنجاح!'),
                backgroundColor: Colors.green,
              ),
            );
            _formKey.currentState!.reset();
            _nameController.clear();
            _emailController.clear();
            _subjectController.clear();
            _messageController.clear();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('فشل إرسال الرسالة. حاول مرة أخرى.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.tertiaryColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Text(
              'الرئيسية',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text(
            'اتصل بنا',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اتصل بنا'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
          child: Column(
          children: [
            // const AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard2'),
            _buildBreadcrumb(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'نرحب بتواصلك معنا!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'الاسم بالكامل',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال اسمك';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال بريدك الإلكتروني';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'يرجى إدخال بريد إلكتروني صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'الموضوع',
                        prefixIcon: Icon(Icons.subject_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال الموضوع';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'الرسالة',
                        prefixIcon: Icon(Icons.message_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال رسالتك';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitForm,
                      icon: _isLoading
                          ? Container(
                              width: 20,
                              height: 20,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isLoading ? 'جاري الإرسال...' : 'إرسال الرسالة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'معلومات الاتصال الأخرى:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildContactInfoTile(
                      icon: Icons.location_on_outlined,
                      title: 'العنوان',
                      subtitle: ContactModule.address,
                      onTap: () => _contactModule.launchUrlUtil(
                          'https://maps.google.com/?q=${Uri.encodeComponent(ContactModule.address)}'),
                    ),
                    _buildContactInfoTile(
                      icon: Icons.phone_outlined,
                      title: 'الهاتف',
                      subtitle: ContactModule.phoneNumber,
                      onTap: () => _contactModule
                          .launchUrlUtil('tel:${ContactModule.phoneNumber}'),
                    ),
                    _buildContactInfoTile(
                      icon: Icons.alternate_email,
                      title: 'البريد الإلكتروني',
                      subtitle: ContactModule.contactEmail,
                      onTap: () => _contactModule.launchEmail(),
                    ),
                    _buildContactInfoTile(
                      icon: Icons.language_outlined,
                      title: 'الموقع الإلكتروني',
                      subtitle: ContactModule.websiteUrl,
                      onTap: () =>
                          _contactModule.launchUrlUtil(ContactModule.websiteUrl),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'تابعنا على:',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildSocialMediaButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor, size: 28),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 14)),
        onTap: onTap,
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey)
            : null,
      ),
    );
  }

  Widget _buildSocialMediaButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ContactModule.socialLinks.entries.map((entry) {
        IconData icon;
        Color color;
        switch (entry.key) {
          case 'facebook':
            icon = Icons.facebook; // Consider using a custom SVG or FontAwesome
            color = const Color(0xFF1877F2);
            break;
          case 'twitter':
            icon = Icons.flutter_dash; // Placeholder, use a Twitter icon
            color = const Color(0xFF1DA1F2);
            break;
          case 'youtube':
            icon = Icons.play_circle_fill; // Placeholder
            color = const Color(0xFFFF0000);
            break;
          case 'instagram':
            icon = Icons.camera_alt; // Placeholder
            color = const Color(0xFFE4405F);
            break;
          default:
            icon = Icons.link;
            color = Colors.grey;
        }
        return IconButton(
          icon: Icon(icon, size: 30),
          color: color,
          onPressed: () => _contactModule.launchUrlUtil(entry.value),
          tooltip: entry.key.capitalize(),
        );
      }).toList(),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
