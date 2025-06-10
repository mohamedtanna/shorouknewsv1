import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // For navigation
import '../../core/theme.dart'; // For consistent styling
// import '../../widgets/ad_banner.dart'; // For displaying ads
import '../../models/additional_models.dart'; // For SubscriptionStatus enum
import 'newsletter_module.dart'; // The module handling newsletter logic

class NewsletterScreen extends StatefulWidget {
  const NewsletterScreen({super.key});

  @override
  State<NewsletterScreen> createState() => _NewsletterScreenState();
}

class _NewsletterScreenState extends State<NewsletterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final NewsletterModule _newsletterModule = NewsletterModule();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    // Validate the form
    if (_formKey.currentState!.validate()) {
      // Set loading state to true
      setState(() => _isLoading = true);

      final String email = _emailController.text.trim();

      try {
        // Call the subscribeToNewsletter method from the module
        final SubscriptionStatus status =
            await _newsletterModule.subscribeToNewsletter(email);

        // Show a SnackBar with the result message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status.message), // Use the message from the enum
              backgroundColor: status == SubscriptionStatus.success || status == SubscriptionStatus.mailNotApproved
                  ? Colors.green // Green for success or needs confirmation
                  : Colors.red, // Red for failures
            ),
          );

          // If subscription was successful or needs confirmation, clear the email field
          if (status == SubscriptionStatus.success || status == SubscriptionStatus.mailNotApproved) {
            _emailController.clear();
          }
        }
      } catch (e) {
        // Handle any unexpected errors during the subscription process
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ غير متوقع: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        // Set loading state back to false
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
            onTap: () => context.go('/home'),
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
            'القائمة البريدية',
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
        title: const Text('القائمة البريدية'), // "Newsletter"
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'), // Navigate back to home
        ),
      ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Advertisement Banner
              // const AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard2'),
            _buildBreadcrumb(),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Introductory Text
                    Text(
                      'اشترك في قائمتنا البريدية ليصلك كل جديد!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'كن أول من يعلم بآخر الأخبار والمقالات الحصرية مباشرة في بريدك الإلكتروني.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Email Input Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني', // "Email"
                        hintText: 'ادخل بريدك الإلكتروني هنا', // "Enter your email here"
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr, // Ensure LTR for email input
                      textAlign: TextAlign.right, // Align text to the right for Arabic context
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال بريدك الإلكتروني'; // "Please enter your email"
                        }
                        // Use the validation from the module
                        if (!_newsletterModule.isValidEmail(value.trim())) {
                          return 'يرجى إدخال بريد إلكتروني صحيح'; // "Please enter a valid email"
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Subscribe Button
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _subscribe,
                      icon: _isLoading
                          ? Container( // Loading indicator
                              width: 20,
                              height: 20,
                              padding: const EdgeInsets.all(2.0),
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(_isLoading ? 'جاري الاشتراك...' : 'اشتراك'), // "Subscribing..." : "Subscribe"
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
                    const SizedBox(height: 20),
                     // Informational text about privacy or what to expect
                    Text(
                      'نحن نحترم خصوصيتك ولن نشارك بياناتك مع أي طرف ثالث. يمكنك إلغاء الاشتراك في أي وقت.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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
