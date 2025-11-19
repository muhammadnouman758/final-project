# Smart PDF Chat Assistant

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.2-0175C2?style=for-the-badge&logo=dart)
![AI Powered](https://img.shields.io/badge/AI-Gemini-FF6D00?style=for-the-badge&logo=google)
![Cross Platform](https://img.shields.io/badge/Cross-Platform-8A2BE2?style=for-the-badge)

**Revolutionize how you interact with documents using AI-powered conversations**

[Features](#-features) • [Installation](#-installation) • [Quick Start](#-quick-start) • [Tech Stack](#-tech-stack) • [Contributing](#-contributing)

</div>

## 🚀 Features

### 🤖 AI-Powered Document Intelligence
- **Smart Q&A**: Ask complex questions about your PDF content
- **Document Summarization**: Get concise overviews of lengthy documents
- **Contextual Understanding**: AI maintains conversation context throughout sessions

### 🎙️ Multi-Modal Interaction
- **Voice Commands**: Speak naturally to ask questions
- **Text Chat**: Traditional typing interface
- **Real-time Responses**: Instant AI-powered answers

### 📱 Modern UX
- **Seamless Uploads**: Drag & drop PDF support
- **Conversation History**: Persistent chat sessions
- **Markdown Rendering**: Beautifully formatted responses
- **Dark/Light Theme**: Adaptive UI based on system preferences

## ⚡ Quick Start

### Prerequisites
- Flutter SDK 3.19+
- Dart 3.2+
- Gemini API Key ([Get one here](https://aistudio.google.com/app/apikey))

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/smart-pdf-chat.git
cd smart-pdf-chat

# Install dependencies
flutter pub get

# Set up environment variables
cp .env.example .env
```

Configure your environment:

```env
GEMINI_API_KEY=your_actual_gemini_api_key_here
GEMINI_MODEL=gemini-1.5-flash
```

### Running the App

```bash
# Development mode
flutter run

# Build for production
flutter build apk --release
```

## 🎯 Usage Examples

### Document Analysis
```
👤 "Summarize the key points from this research paper"
🤖 Provides concise summary with main findings

👤 "What are the main methodologies discussed?"
🤖 Lists and explains research methods

👤 "Extract all references mentioned"
🤖 Compiles bibliography from document
```

### Voice Interaction
```dart
// Tap mic icon and speak naturally
"Find the project timeline in this document"
// AI responds with relevant timeline information
```

## 🏗️ Tech Stack

### Core Framework
- **Flutter 3.19+** - Cross-platform UI toolkit
- **Dart 3.2** - Null-safe, modern language features

### AI & ML
- **Google Gemini AI** - Advanced document understanding
- **Custom Prompts** - Optimized for PDF content analysis

### Voice Processing
- `speech_to_text` - Accurate speech recognition
- `flutter_tts` - Natural voice responses

### Data & Storage
- `sqflite` - Local conversation database
- `file_picker` - Secure document selection
- `path_provider` - Cross-platform file handling

### UI & UX
- `flutter_markdown` - Rich text rendering
- `lottie` - Smooth animations
- Adaptive design - Responsive across all platforms

## 📁 Project Structure

```
lib/
├── core/                           # Core functionality & infrastructure
│   ├── services/                   # Business logic & API clients
│   │   ├── genai_client.dart              # Gemini API client for document processing
│   │   └── genai_file_manager.dart        # File upload & retrieval management
│   ├── models/                     # Data models (entities, API responses)
│   │   ├── chat_message.dart              # Chat message model
│   │   ├── genai_file_model.dart          # File metadata model for Gemini API
│   │   └── genai_generated_response_model.dart  # API response model
│   └── constants/                  # App-wide constants (API keys, config)
│
├── features/                       # Feature-specific modules
│   ├── chat/                       # Chat management feature
│   │   ├── chat_his_db.dart              # SQLite database operations
│   │   ├── chat_his_repo.dart            # Repository pattern for chat history
│   │   ├── chat_his_screen.dart          # Chat history UI screen
│   │   └── pdf_chat_screen.dart          # Main PDF chat interface
│   │
│   ├── documents/                  # Document handling (future expansion)
│   │   └── (reserved for PDF upload, processing, storage)
│   │
│   ├── voice/                      # Voice interaction feature
│   │   ├── voice_chat.dart               # Voice input/TTS chat screen
│   │   └── voice_models.dart             # Voice-specific data models (VoiceChatMessage, etc)
│   │
│   └── onboarding/                 # User onboarding flow
│       ├── splash.dart                   # Splash screen
│       └── (onboarding screens & info)
│
├── shared/                         # Shared across features
│   ├── widgets/                    # Reusable UI components
│   │   ├── chat_bubble.dart              # Chat message bubble widget
│   │   ├── typing_indicator.dart         # Animated typing indicator
│   │   ├── animated_background.dart      # Animated background component
│   │   └── (other reusable widgets)
│   │
│   └── utils/                      # Helper functions & utilities
│       ├── validators.dart               # Input validation helpers
│       ├── formatters.dart               # Date/time formatting
│       └── (other utilities)
│
├── main.dart                       # App entry point & MaterialApp setup
├── pdf_gemini.dart                 # (Legacy - can be moved to core/constants)
├── chatbot.dart                    # (Legacy - can be refactored)
└── home_page.dart                  # (Legacy - can be integrated into features)
```

## 🛠️ Development

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Test coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
dart format .

# Fix dependencies
flutter pub outdated
flutter pub upgrade
```

## 🤝 Contributing

We love contributions! Here's how to help:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'Add amazing feature'`
4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

### Development Setup
```bash
# Enable Flutter desktop support (if needed)
flutter config --enable-<platform>-desktop

# Get all dependencies
flutter pub get

# Generate localization files (if applicable)
flutter gen-l10n
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📧 **Email**: m.nouman5710@gmail.com
- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/smart-pdf-chat/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/smart-pdf-chat/discussions)

## 🙏 Acknowledgments

- Google Gemini AI for powerful document understanding
- Flutter community for excellent packages
- Contributors who help improve this project

---

<div align="center">

**Ready to transform your document workflow?** Give us a ⭐ on GitHub!

*"Making document interaction smarter, one chat at a time"*

</div>
