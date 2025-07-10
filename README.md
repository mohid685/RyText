# RyText - AI-Powered Messenger

<div align="center">
  
![RyText Logo](https://img.shields.io/badge/RyText-Messenger-4CAF50?style=for-the-badge&logo=chat&logoColor=white)

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini AI](https://img.shields.io/badge/Gemini-AI-4285F4?style=flat&logo=google&logoColor=white)](https://ai.google.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**A modern Flutter messenger app with integrated Gemini AI assistant**

*Connect with friends and get AI assistance seamlessly in your conversations*

</div>

---

##  About RyText

RyText is a cutting-edge messaging application built with Flutter that combines traditional real-time messaging with the power of Google's Gemini AI. Users can have normal conversations with friends and instantly get AI assistance by simply typing `@RyAI` followed by their question.

###  Key Features

-  **Real-time Messaging** - Instant message delivery powered by Firebase
-  **AI Assistant** - Integrated Gemini AI accessible via `@RyAI` commands  
-  **Secure Authentication** - Email and phone number sign-up
-  **Smart Contacts** - Privacy-focused contact management
-  **Modern UI** - Beautiful dark theme with smooth animations
-  **Cross-platform** - Android, iOS, Web, Windows, macOS, Linux
-  **Live Notifications** - In-app notifications with quick reply
-  **Privacy First** - Users control who appears in their contact list

---

##  Technologies Used

- **Frontend**: Flutter 3.x, Dart
- **Backend**: Firebase (Authentication, Firestore)
- **AI Integration**: Google Gemini AI API
- **State Management**: Built-in Flutter state management
- **Real-time Database**: Cloud Firestore
- **Authentication**: Firebase Auth (Email/Phone)

---

##  Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  http: ^1.1.0
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

##  Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.0.0 or higher)
- [Dart SDK](https://dart.dev/get-dart) (3.0.0 or higher)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- [Git](https://git-scm.com/)

### Installation & Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/rytext-messenger.git
   cd rytext-messenger
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password and Phone)
   - Enable Cloud Firestore Database
   - Download configuration files:
     - `google-services.json` → Place in `android/app/`
     - `GoogleService-Info.plist` → Place in `ios/Runner/`

4. **Configure Gemini AI**
   - Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create `lib/gemini_config.dart`:
   ```dart
   class GeminiConfig {
     static const String apiKey = 'YOUR_GEMINI_API_KEY_HERE';
   }
   ```

5. **Run the application**
   ```bash
   # Debug mode
   flutter run
   
   # Release mode
   flutter run --release
   
   # Specific platform
   flutter run -d chrome     # Web
   flutter run -d windows    # Windows
   flutter run -d macos      # macOS
   ```

### Build Commands

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (requires macOS)
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

---

##  API Key Setup

### Gemini AI Configuration

1. **Get API Key**
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Sign in with your Google account
   - Click "Create API Key"
   - Copy the generated key

2. **Add to Project**
   Create `lib/gemini_config.dart`:
   ```dart
   class GeminiConfig {
     static const String apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   }
   ```

3. **Security Note**
   - Never commit API keys to version control
   - Add `lib/gemini_config.dart` to your `.gitignore`
   - For production, use environment variables or secure key management

---

## Screenshots

<div align="center">

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/018a5538-97ab-4086-9646-baa28e74f702" width="400" />
      <br/>
      <b>User Registration</b><br/>
      Sign up with email, phone number, and custom avatar
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/6a3acf48-694d-48a3-bf8d-78f5244724d9" width="400" />
      <br/>
      <b>Chat Interface with AI Integration</b><br/>
      Real-time messaging with @RyAI assistant responses
    </td>
  </tr>
</table>

</div>


##  How to Use

### Basic Messaging
1. **Sign Up** - Create account with email and phone number
2. **Add Contacts** - Search and add friends by phone number
3. **Start Chatting** - Send real-time messages to your contacts

### AI Assistant
1. **Activate RyAI** - Type `@RyAI` followed by your question
2. **Get Responses** - Receive intelligent AI responses in the chat
3. **Context Aware** - AI understands conversation context

### Example AI Usage
```
You: @RyAI What's the weather like today?
RyAI: I can help you with general information, but I don't have access to real-time weather data. You might want to check a weather app or website for current conditions in your area.

You: @RyAI Explain quantum computing in simple terms
RyAI: Quantum computing is like having a super-powerful computer that uses the strange rules of quantum physics...
```

---

##  Project Structure

```
rytext-messenger/
├── lib/
│   ├── main.dart              # App entry point
│   ├── firebase_service.dart  # Firebase integration
│   ├── gemini_service.dart    # AI integration
│   ├── firebase_options.dart  # Firebase config
│   └── gemini_config.dart     # API key (create this)
├── android/                   # Android platform files
├── ios/                      # iOS platform files
├── web/                      # Web platform files
├── windows/                  # Windows platform files
├── docs/
│   └── screenshots/          # App screenshots
├── pubspec.yaml              # Project configuration
└── README.md                 # This file
```

---

##  Firebase Setup Guide

### 1. Create Firebase Project
- Go to [Firebase Console](https://console.firebase.google.com/)
- Click "Add project"
- Follow the setup wizard

### 2. Configure Authentication
- Navigate to Authentication → Sign-in method
- Enable "Email/Password"
- Enable "Phone" (optional)

### 3. Setup Firestore Database
- Go to Firestore Database
- Click "Create database"
- Choose "Start in test mode"
- Select your preferred location

### 4. Add Your App
- Click project settings → Add app
- Choose your platform (Android/iOS/Web)
- Download configuration files
- Place them in the correct directories

---

##  Troubleshooting

### Common Issues

**Build Errors**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**Firebase Connection Issues**
- Verify configuration files are in correct locations
- Check Firebase project settings
- Ensure APIs are enabled

**Gemini AI Not Working**
- Verify API key is correct
- Check `gemini_config.dart` exists
- Ensure stable internet connection

---

##  Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Guidelines
- Follow Flutter/Dart style guidelines
- Add comments for complex logic
- Test your changes thoroughly
- Update documentation if needed

---

##  License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 RyText Messenger

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

---

##  Acknowledgments

- [Flutter Team](https://flutter.dev/) - Amazing cross-platform framework
- [Firebase](https://firebase.google.com/) - Reliable backend services  
- [Google AI](https://ai.google.dev/) - Powerful Gemini AI models
- [Material Design](https://material.io/) - Beautiful UI guidelines
- [Open Source Community](https://github.com/) - Inspiration and support

---

##  Created By

**Mohid Faisal**
-  Email: [mohidx186@gmail.com](mailto:your.email@example.com)
-  LinkedIn: [linkedin.com/in/yourprofile](https://linkedin.com/in/yourprofile)
-  GitHub: [mohid685](https://github.com/mohid685)

---

##  Support

If you found this project helpful, please consider:
-  Starring this repository
-  Reporting bugs
-  Suggesting new features
-  Contributing to the code

---
