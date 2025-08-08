# 🤖 AI Chatbot - Flutter App

A beautiful, feature-rich AI chatbot application built with Flutter and powered by Google's Gemini 2.0 Flash AI model.

## ✨ Features

### 🎤 **Voice Interaction**
- Real-time speech-to-text conversion
- Animated microphone with visual feedback
- Live transcription display
- Multi-language support

### 📎 **Multi-Format Attachments**
- **🖼️ Images**: Gallery selection and camera capture
- **📄 Documents**: PDF, DOC, DOCX, TXT, XLSX, PPTX support
- **🎵 Audio**: All common audio file formats
- Beautiful attachment previews with type-specific icons

### 🎨 **Modern UI/UX**
- Stunning blue gradient theme
- Smooth animations and transitions
- Responsive design for all screen sizes
- Professional message bubbles with gradients
- Animated button interactions

### 🤖 **AI Capabilities**
- Powered by Gemini 2.0 Flash (latest AI model)
- Intelligent image analysis and text extraction
- Enhanced conversation memory
- Smart fallback system for reliability

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.32.2 or later)
- Dart SDK
- Android Studio or VS Code
- Android/iOS emulator or physical device

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/chatbot.git
   cd chatbot
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up API Key**
   - Get a Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Replace the API key in `lib/services/gemini_service.dart`:
   ```dart
   static const String apiKey = 'YOUR_API_KEY_HERE';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 How to Use

### **Sending Messages**
- Type in the input field and tap send
- Use voice input by tapping the microphone button
- Attach files using the attachment button

### **Attachments**
- **Images**: Tap attach → Choose Gallery or Camera
- **Documents**: Tap attach → Select Document
- **Audio**: Tap attach → Choose Audio File

### **Voice Input**
- Tap the microphone button
- Speak clearly
- Watch real-time transcription
- Text automatically fills the input field

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── message_model.dart    # Message data model
├── providers/
│   └── chat_provider.dart    # State management
├── screens/
│   └── simple_chat_screen.dart # Main chat interface
├── services/
│   └── gemini_service.dart   # AI service integration
└── widgets/
    ├── enhanced_chat_input.dart    # Input with all features
    ├── enhanced_message_bubble.dart # Message display
    └── simple_welcome_screen.dart  # Welcome screen
```

## 🛠️ Technologies Used

- **Framework**: Flutter 3.32.2
- **State Management**: Provider
- **AI Model**: Google Gemini 2.0 Flash
- **Voice Recognition**: speech_to_text
- **File Picking**: file_picker, image_picker
- **UI Components**: flutter_spinkit
- **HTTP Requests**: http package

## 🔧 Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  provider: ^6.1.2
  http: ^1.2.1
  flutter_spinkit: ^5.2.0
  intl: ^0.20.2
  image_picker: ^1.0.7
  speech_to_text: ^7.0.0
  file_picker: ^8.0.0+1
  shared_preferences: ^2.2.2
```

## 🎨 Features Showcase

### **Beautiful UI**
- Modern blue gradient theme
- Smooth animations and transitions
- Professional message design
- Responsive layouts

### **Smart Attachments**
- Type-specific file previews
- Color-coded attachment cards
- Easy file management
- Error handling

### **Voice Integration**
- Real-time speech recognition
- Visual feedback during recording
- Automatic text insertion
- Multi-language support

## 📈 Performance

- **Optimized animations** for 60fps smoothness
- **Efficient state management** with Provider
- **Smart memory handling** for file attachments
- **Responsive design** for all screen sizes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Google Gemini AI for powerful language processing
- Flutter team for the amazing framework
- Community contributors and testers

## 📞 Support

If you have any questions or issues, please open an issue on GitHub or contact the maintainers.

---

**Made with ❤️ using Flutter and Gemini AI**
