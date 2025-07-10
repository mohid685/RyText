# My Messenger App

A modern, cross-platform messenger app built with Flutter. Connect, chat, and share instantly across devices with a beautiful, intuitive interface.

---

## Features

### Implemented Features

- **User Authentication**
  - Email/password sign up and sign in
  - User profile creation with name, avatar, and phone number
  - Secure Firebase Authentication integration

- **Real-time Messaging**
  - Live chat functionality with Firebase Firestore
  - Real-time message synchronization
  - Message timestamps and sender identification
  - In-app notifications for new messages

- **Contact Management**
  - Add contacts with name, avatar, and phone number
  - Contact list with search functionality
  - Automatic contact upgrade when users register
  - Online/offline status tracking

- **Modern UI/UX**
  - Neon green and black theme
  - Glassmorphic design elements
  - Smooth animations and transitions
  - Responsive layout for different screen sizes

- **Cross-platform Support**
  - Android and Web 

### In Progress / Planned Features

- Group chats
- Media sharing (images, files)
- Push notifications
- Message encryption
- Voice/video calls

---

## Screenshots

<!-- Replace with your own screenshots -->
| Home Screen | Chat Screen |
|-------------|------------|
| ![Home](docs/screenshots/home.png) | ![Chat](docs/screenshots/chat.png) |

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart
- Android Studio / Xcode / VS Code
- Firebase project setup

### Installation
```bash
# Clone the repository
$ git clone https://github.com/yourusername/my_messenger_app.git
$ cd my_messenger_app

# Install dependencies
$ flutter pub get

# Configure Firebase
# 1. Create a Firebase project
# 2. Add your Firebase configuration files
# 3. Enable Authentication and Firestore

# Run the app
$ flutter run
```

---

## Folder Structure

```
my_messenger_app/
├── lib/                # Main application code
│   ├── main.dart       # Main app entry point
│   ├── firebase_service.dart  # Firebase integration
│   └── firebase_options.dart  # Firebase configuration
├── android/            # Android-specific files
├── ios/                # iOS-specific files
├── web/                # Web-specific files
├── macos/              # macOS-specific files
├── windows/            # Windows-specific files
├── linux/              # Linux-specific files
├── test/               # Unit and widget tests
├── pubspec.yaml        # Flutter dependencies
└── README.md           # Project documentation
```

---

## Technologies Used

- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **Firebase** - Backend services
  - Firebase Authentication - User management
  - Cloud Firestore - Real-time database
- **Provider/State Management** - Built-in Flutter state management

---

## Current Implementation Details

### Authentication
- Email/password authentication via Firebase Auth
- User profile creation with name, avatar, and phone number
- Automatic user profile management

### Messaging System
- Real-time chat using Firestore collections
- Message persistence and synchronization
- In-app notifications for new messages
- Contact-based chat organization

### Contact System
- Add contacts manually with phone number lookup
- Automatic contact upgrade when users register
- Contact search functionality
- Online/offline status tracking

### UI/UX Features
- Neon green and black theme throughout the app
- Glassmorphic design with blur effects
- Smooth animations for message bubbles and transitions
- Responsive design for different screen sizes

---

## Contributing

Contributions are welcome! Please open issues and submit pull requests for new features, bug fixes, or improvements.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/YourFeature`)
3. Commit your changes (`git commit -m 'Add some feature'`)
4. Push to the branch (`git push origin feature/YourFeature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Contact

Created by [Your Name](mailto:your.email@example.com) · [GitHub](https://github.com/yourusername)

---

> _"Connecting people, one message at a time."_
