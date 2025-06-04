import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 16.0),
            Text(
              'This Privacy Policy describes how your personal information is collected, used, and shared when you visit or make a purchase from [Your App Name] (the "App").',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: 16.0),
            Text(
              'Personal Information We Collect',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8.0),
            Text(
              'When you visit the App, we automatically collect certain information about your device, including information about your web browser, IP address, time zone, and some of the cookies that are installed on your device. Additionally, as you browse the App, we collect information about the individual web pages or products that you view, what websites or search terms referred you to the App, and information about how you interact with the App. We refer to this automatically-collected information as "Device Information".',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: 16.0),
            Text(
              'How We Use Your Personal Information',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8.0),
            Text(
              'We use the Device Information that we collect to help us screen for potential risk and fraud (in particular, your IP address), and more generally to improve and optimize our App (for example, by generating analytics about how our customers browse and interact with the App, and to assess the success of our marketing and advertising campaigns).',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: 16.0),
            Text(
              'Sharing Your Personal Information',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8.0),
            Text(
              'We share your Personal Information with third parties to help us use your Personal Information, as described above. For example, we use Google Analytics to help us understand how our customers use the App--you can read more about how Google uses your Personal Information here: https://www.google.com/intl/en/policies/privacy/. You can also opt-out of Google Analytics here: https://tools.google.com/dlpage/gaoptout.',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: 16.0),
            Text(
              'Your Rights',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8.0),
            Text(
              'If you are a European resident, you have the right to access personal information we hold about you and to ask that your personal information be corrected, updated, or deleted. If you would like to exercise this right, please contact us through the contact information below.',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: 16.0),
            Text(
              'Changes',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8.0),
            Text(
              'We may update this privacy policy from time to time in order to reflect, for example, changes to our practices or for other operational, legal or regulatory reasons.',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: 16.0),
            Text(
              'Contact Us',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8.0),
            Text(
              'For more information about our privacy practices, if you have questions, or if you would like to make a complaint, please contact us by e-mail at [your email address] or by mail using the details provided below:',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: 8.0),
            Text(
              '[Your Address]',
              style: Theme.of(context).textTheme.bodyText2,
            ),
            SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}