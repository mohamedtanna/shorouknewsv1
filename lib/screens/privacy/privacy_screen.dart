import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart'; // For rendering HTML if needed
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
// import '../../widgets/ad_banner.dart';
import '../../widgets/section_app_bar.dart';
import 'privacy_module.dart'; // Import the module

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  String _privacyPolicyText = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  Future<void> _loadPrivacyPolicy() async {
    setState(() => _isLoading = true);
    // Simulate fetching if it were from a remote source
    // await Future.delayed(const Duration(milliseconds: 100));
    final policyText = PrivacyModule.getPrivacyPolicyText();
    if (mounted) {
      setState(() {
        _privacyPolicyText = policyText;
        _isLoading = false;
      });
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
            'سياسة الخصوصية',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SectionAppBar(
        title: const Text('سياسة الخصوصية'),
        automaticallyImplyLeading: false,
      ),
        body: Column(
        children: [
          // const AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard2'),
          _buildBreadcrumb(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // If your policy text might contain HTML:
                        Html(
                          data: _privacyPolicyText,
                          style: {
                            "body": Style(
                              fontSize: FontSize(15),
                              lineHeight: const LineHeight(1.6),
                              textAlign: TextAlign.justify,
                            ),
                            "h1": Style(
                                fontSize: FontSize(20),
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                margin: Margins.only(top: 16, bottom: 8)),
                            "h2": Style(
                                fontSize: FontSize(18),
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                                margin: Margins.only(top: 12, bottom: 6)),
                             "h3": Style(
                                fontSize: FontSize(16),
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryColor,
                                margin: Margins.only(top: 10, bottom: 4)),
                            "p": Style(
                              margin: Margins.only(bottom: 10),
                            ),
                            "li": Style(
                              margin: Margins.only(bottom: 6),
                            ),
                            "a": Style(
                              color: AppTheme.tertiaryColor,
                              textDecoration: TextDecoration.underline,
                            ),
                          },
                          onLinkTap: (url, attributes, element) async {
                            if (url != null) {
                              final uri = Uri.tryParse(url);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              } else {
                                debugPrint('Could not launch $url');
                              }
                            }
                          },
                        ),
                        // If your policy text is guaranteed to be plain text:
                        // SelectableText(
                        //   _privacyPolicyText,
                        //   style: TextStyle(fontSize: 15, height: 1.6),
                        //   textAlign: TextAlign.justify,
                        // ),
                        const SizedBox(height: 20),
                        // Optional: Button to acknowledge or manage preferences
                        // Center(
                        //   child: ElevatedButton(
                        //     onPressed: () {
                        //       PrivacyModule.recordPrivacyPolicyAcceptance();
                        //       ScaffoldMessenger.of(context).showSnackBar(
                        //         const SnackBar(content: Text('تم حفظ تفضيلات الخصوصية.')),
                        //       );
                        //     },
                        //     child: const Text('لقد قرأت وأوافق على سياسة الخصوصية'),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
