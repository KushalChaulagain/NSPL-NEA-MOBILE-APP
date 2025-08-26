# NSPL Field Agent Mobile App

A mobile application for NSPL field agents to manage service tickets, capture meter readings, and complete tasks efficiently.

## Getting Started

1. Clone the repository
2. Make sure you have Flutter installed and properly set up
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the application

## Setting Up the App Icon

To generate app icons for different platforms, follow these steps:

1. Ensure you have the proper `nspl_logo.jpg` file in the `assets/images/` directory
2. Run the following command in the terminal:

```
flutter pub get
flutter pub run flutter_launcher_icons
```

This will generate app icons for Android, iOS, and Web platforms using the NSPL logo.

## Features

- JWT Authentication
- Ticket management
- Meter photo capture
- Task completion
- User profile management

## Dependencies

- Flutter
- Provider for state management
- HTTP for API communication
- Image Picker for capturing photos
- Flutter Secure Storage for secure token storage
- And more (see pubspec.yaml)