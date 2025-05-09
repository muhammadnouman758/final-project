# Smart PDF Chat Assistant

![App Screenshot](https://via.placeholder.com/800x500.png?text=Smart+PDF+Chat+Assistant+Screenshot)

A powerful Flutter application that enables both voice and text-based interaction with PDF documents using Google's Gemini AI.

## Features ✨

- **Dual Interface**: Choose between voice or text chat modes
- **PDF Processing**: Upload and analyze PDF documents
- **AI-powered Insights**: Get summaries and answers about your documents
- **Conversation History**: Save and restore previous chat sessions
- **Rich Formatting**: Markdown support for beautifully formatted responses
- **Voice Interaction**: Speak naturally and receive spoken responses
- **Suggested Questions**: Get AI-generated questions to explore your documents
- **Cross-platform**: Works on iOS, Android, and web

## Installation 🛠️

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Google Gemini API key

### Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/smart-pdf-chat.git
   cd smart-pdf-chat
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Add your Gemini API key:
   - Create a `.env` file in the root directory
   - Add: `GEMINI_API_KEY=your_api_key_here`

4. Run the app:
   ```bash
   flutter run
   ```

## Usage Guide 📖

### Voice Chat Mode
1. Tap the microphone icon to start speaking
2. Ask questions about your uploaded PDF
3. Receive spoken answers with visual feedback
4. Use suggested questions to explore the document

### Text Chat Mode
1. Type your question in the input field
2. Press send or hit enter
3. View formatted responses with Markdown support
4. Copy messages or explore conversation history

### Document Upload
1. Tap the upload button
2. Select a PDF file from your device
3. Wait for processing to complete
4. Start asking questions

## Technical Architecture 🏗️

### Core Components
- **Gemini API Integration**: For document processing and question answering
- **Speech Recognition**: Powered by `speech_to_text` package
- **Text-to-Speech**: Using `flutter_tts`
- **Local Database**: SQLite for conversation history
- **State Management**: Built-in Flutter state management

### Packages Used
- `file_picker`: For PDF selection
- `speech_to_text`: Voice input
- `flutter_tts`: Voice output
- `sqflite`: Local storage
- `flutter_markdown`: Rich text rendering
- `animated_text_kit`: Typing animations

## Screenshots 📸

| Voice Chat Mode | Text Chat Mode | Document Upload |
|-----------------|----------------|-----------------|
| ![Voice](https://via.placeholder.com/300x500.png?text=Voice+Mode) | ![Text](https://via.placeholder.com/300x500.png?text=Text+Mode) | ![Upload](https://via.placeholder.com/300x500.png?text=Document+Upload) |

## Contributing 🤝

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request




## Support 💬

For support or feature requests, please open an issue on GitHub or contact us at support@smartpdfchat.com

---

**Happy Document Exploring!** 📄💬
