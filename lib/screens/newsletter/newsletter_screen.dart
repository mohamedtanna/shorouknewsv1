import 'package:flutter/material.dart';

class NewsletterScreen extends StatefulWidget {
  @override
  _NewsletterScreenState createState() => _NewsletterScreenState();
}

class _NewsletterScreenState extends State<NewsletterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';

  void _subscribe() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Process the subscription with the _email
      print('Subscribing with email: $_email');
      // You would typically send this email to a service or backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing Subscription')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Newsletter Subscription'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Subscribe to our newsletter for the latest updates!',
                style: Theme.of(context).textTheme.headline6,
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onSaved: (value) {
                  _email = value!;
                