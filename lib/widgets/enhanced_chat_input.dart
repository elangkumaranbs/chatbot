import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class EnhancedChatInput extends StatefulWidget {
  const EnhancedChatInput({super.key});

  @override
  State<EnhancedChatInput> createState() => _EnhancedChatInputState();
}

class _EnhancedChatInputState extends State<EnhancedChatInput>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  bool _isComposing = false;
  File? _selectedFile;
  String? _selectedFileType;
  final ImagePicker _picker = ImagePicker();
  String? _fileUrl;

  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';

  // Animation controllers
  late AnimationController _sendButtonController;
  late AnimationController _micButtonController;
  late AnimationController _attachButtonController;
  late AnimationController _inputController;

  late Animation<double> _sendButtonScale;
  late Animation<double> _micButtonScale;
  late Animation<double> _attachButtonScale;
  late Animation<double> _inputBorderWidth;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initAnimations();
  }

  void _initAnimations() {
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _micButtonController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _attachButtonController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _inputController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sendButtonScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.elasticOut),
    );
    _micButtonScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _micButtonController, curve: Curves.easeInOut),
    );
    _attachButtonScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _attachButtonController, curve: Curves.easeInOut),
    );
    _inputBorderWidth = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _inputController, curve: Curves.easeInOut),
    );

    // Start initial animations
    _attachButtonController.forward();
  }

  @override
  void dispose() {
    _textController.dispose();
    _sendButtonController.dispose();
    _micButtonController.dispose();
    _attachButtonController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  // Initialize speech recognition
  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: (error) => print('Speech Error: $error'),
    );
    if (!available) {
      print('Speech recognition not available');
    }
  }

  // Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    print('Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      setState(() {
        _isListening = false;
      });
      _micButtonController.reverse();
    }
  }

  // Start/stop listening to speech
  void _toggleListening() async {
    if (!_isListening) {
      _micButtonController.forward();
      bool available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (val) => print('Speech Error: $val'),
      );

      if (available) {
        setState(() {
          _isListening = true;
          _recognizedText = '';
        });

        await _speech.listen(
          onResult: _onSpeechResult,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          localeId: 'en_US',
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
      });
      _micButtonController.reverse();
    }
  }

  // Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _recognizedText = result.recognizedWords;

      if (result.finalResult) {
        _textController.text = _recognizedText;
        _isComposing = _textController.text.isNotEmpty;
        if (_isComposing) {
          _sendButtonController.forward();
          _inputController.forward();
        }
      }
    });
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _selectedFileType = 'image';
          _fileUrl = pickedFile.path;
          _isComposing = true;
        });
        _sendButtonController.forward();
        _inputController.forward();
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  // Pick documents
  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'pptx'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileType = 'document';
          _fileUrl = result.files.single.path!;
          _isComposing = true;
        });
        _sendButtonController.forward();
        _inputController.forward();
      }
    } catch (e) {
      _showErrorSnackBar('Error picking document: $e');
    }
  }

  // Pick audio files
  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileType = 'audio';
          _fileUrl = result.files.single.path!;
          _isComposing = true;
        });
        _sendButtonController.forward();
        _inputController.forward();
      }
    } catch (e) {
      _showErrorSnackBar('Error picking audio: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1A1A1A), const Color(0xFF2A2A2A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Choose Attachment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Options Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _buildAttachmentOption(
                        icon: Icons.photo_library_rounded,
                        title: 'Gallery',
                        subtitle: 'Photos & Videos',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.camera_alt_rounded,
                        title: 'Camera',
                        subtitle: 'Take a photo',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.description_rounded,
                        title: 'Document',
                        subtitle: 'PDF, DOC, TXT',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pop(context);
                          _pickDocument();
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.audiotrack_rounded,
                        title: 'Audio',
                        subtitle: 'Music & Voice',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pop(context);
                          _pickAudio();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white70, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearSelectedFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileType = null;
      _fileUrl = null;
      _isComposing = _textController.text.isNotEmpty;
    });
    if (!_isComposing) {
      _sendButtonController.reverse();
      _inputController.reverse();
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty && _selectedFile == null) return;

    _sendButtonController.forward().then((_) {
      _sendButtonController.reverse();
    });

    _textController.clear();
    final fileUrl = _fileUrl;
    final fileType = _selectedFileType;

    setState(() {
      _isComposing = false;
      _selectedFile = null;
      _selectedFileType = null;
      _fileUrl = null;
    });

    _inputController.reverse();

    // Send message using the provider
    Provider.of<ChatProvider>(context, listen: false).sendMessage(
      text.trim().isEmpty ? 'Shared a $fileType' : text,
      imageUrl: fileType == 'image' ? fileUrl : null,
      fileUrl: fileType != 'image' ? fileUrl : null,
      fileType: fileType,
      fileName:
          fileType != 'image' ? _selectedFile?.path.split('/').last : null,
    );
  }

  Widget _buildFilePreview() {
    if (_selectedFile == null) return const SizedBox.shrink();

    IconData icon;
    Color color;
    String fileName = _selectedFile!.path.split('/').last;

    switch (_selectedFileType) {
      case 'image':
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(_selectedFile!),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: _clearSelectedFile,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case 'document':
        icon = Icons.description_rounded;
        color = Colors.orange;
        break;
      case 'audio':
        icon = Icons.audiotrack_rounded;
        color = Colors.purple;
        break;
      default:
        icon = Icons.attach_file_rounded;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _selectedFileType!.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearSelectedFile,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.red, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0F0F0F), const Color(0xFF1A1A1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          // Voice recognition indicator
          if (_isListening)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  SpinKitPulse(
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _recognizedText.isEmpty
                          ? 'Listening... Speak now'
                          : _recognizedText,
                      style: TextStyle(
                        color: Colors.white70,
                        fontStyle:
                            _recognizedText.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // File preview
          _buildFilePreview(),

          // Input row
          Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _inputBorderWidth,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1A1A1A),
                            const Color(0xFF2A2A2A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25.0),
                        border: Border.all(
                          color:
                              _isComposing
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.8)
                                  : Colors.transparent,
                          width: _inputBorderWidth.value,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                _isComposing
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.3)
                                    : Colors.black26,
                            blurRadius: _isComposing ? 12 : 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _textController,
                        onChanged: (text) {
                          setState(() {
                            _isComposing =
                                text.isNotEmpty || _selectedFile != null;
                          });
                          if (text.isNotEmpty) {
                            _sendButtonController.forward();
                            _inputController.forward();
                          } else if (_selectedFile == null) {
                            _sendButtonController.reverse();
                            _inputController.reverse();
                          }
                        },
                        onSubmitted: _isComposing ? _handleSubmitted : null,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: const TextStyle(
                            color: Colors.white38,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          prefixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),
                              AnimatedBuilder(
                                animation: _attachButtonScale,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _attachButtonScale.value,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          _attachButtonController
                                              .forward()
                                              .then((_) {
                                                _attachButtonController
                                                    .reverse();
                                              });
                                          _showAttachmentOptions();
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.2),
                                                Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                    .withOpacity(0.1),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.attach_file_rounded,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              AnimatedBuilder(
                                animation: _micButtonScale,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _micButtonScale.value,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _toggleListening,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient:
                                                _isListening
                                                    ? LinearGradient(
                                                      colors: [
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.3),
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .secondary
                                                            .withOpacity(0.2),
                                                      ],
                                                    )
                                                    : null,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            _isListening
                                                ? Icons.mic_rounded
                                                : Icons.mic_none_rounded,
                                            color:
                                                _isListening
                                                    ? Theme.of(
                                                      context,
                                                    ).colorScheme.primary
                                                    : Colors.white70,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12.0),
              Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  return AnimatedBuilder(
                    animation: _sendButtonScale,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _sendButtonScale.value,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient:
                                _isComposing && !chatProvider.isLoading
                                    ? LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                    : LinearGradient(
                                      colors: [
                                        Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.3),
                                        Theme.of(context).colorScheme.secondary
                                            .withOpacity(0.2),
                                      ],
                                    ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow:
                                _isComposing && !chatProvider.isLoading
                                    ? [
                                      BoxShadow(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.5),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(26),
                              onTap:
                                  _isComposing && !chatProvider.isLoading
                                      ? () =>
                                          _handleSubmitted(_textController.text)
                                      : null,
                              child:
                                  chatProvider.isLoading
                                      ? SpinKitPulse(
                                        color: Colors.white,
                                        size: 22,
                                      )
                                      : Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
