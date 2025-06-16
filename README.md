# myapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Push Notifications

This project integrates Firebase Cloud Messaging together with
`flutter_local_notifications` to display notifications when messages arrive.
Ensure you have added the appropriate Firebase configuration files for each
platform before building the app.

The repository includes a `lib/firebase_options.dart` file with placeholder
values. Replace these placeholders with your actual Firebase project settings
or regenerate the file using the FlutterFire CLI:

```bash
flutterfire configure
```

After updating the configuration, rebuild the application.
