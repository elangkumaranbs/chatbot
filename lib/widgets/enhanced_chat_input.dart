import 'package:flutter/material.dart';
import '../providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt; // Temporarily disabled
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

  // Voice to text - temporarily disabled
  // final stt.SpeechToText _speech = stt.SpeechToText();
  // bool _isListening = false;
  // bool _speechAvailable = false;

  // Animation controllers
  late AnimationController _sendButtonController;
  // late AnimationController _micButtonController; // Temporarily disabled for voice
  late AnimationController _attachButtonController;
  late AnimationController _inputController;

  late Animation<double> _sendButtonScale;
  // late Animation<double> _micButtonScale; // Temporarily disabled for voice
  late Animation<double> _attachButtonScale;
  late Animation<double> _inputBorderWidth;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
    _attachButtonController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
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

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Choose Attachment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(Icons.camera_alt, 'Camera', () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    }),
                    _buildAttachmentOption(Icons.photo_library, 'Gallery', () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    }),
                    _buildAttachmentOption(Icons.description, 'Document', () {
                      Navigator.pop(context);
                      _pickDocument();
                    }),
                    _buildAttachmentOption(Icons.audiotrack, 'Audio', () {
                      Navigator.pop(context);
                      _pickAudio();
                    }),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _clearAttachment() {
    setState(() {
      _selectedFile = null;
      _selectedFileType = null;
      _fileUrl = null;
      if (_textController.text.isEmpty) {
        _isComposing = false;
        _sendButtonController.reverse();
        _inputController.reverse();
      }
    });
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty && _selectedFile == null) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    _textController.clear();
    setState(() {
      _isComposing = false;
    });
    _sendButtonController.reverse();
    _inputController.reverse();

    if (_selectedFile != null) {
      if (_selectedFileType == 'image') {
        // For images, use imageUrl parameter
        await chatProvider.sendMessage(
          text.trim().isEmpty ? 'Shared an image' : text.trim(),
          imageUrl: _fileUrl,
        );
      } else {
        // For other files, use fileUrl and fileType
        await chatProvider.sendMessage(
          text.trim().isEmpty ? 'Attached file' : text.trim(),
          fileUrl: _fileUrl,
          fileType: _selectedFileType,
          fileName: _selectedFile!.path.split('/').last,
        );
      }
      _clearAttachment();
    } else {
      await chatProvider.sendMessage(text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          if (_selectedFile != null) _buildAttachmentPreview(),
          AnimatedBuilder(
            animation: _inputBorderWidth,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                    width: _inputBorderWidth.value,
                  ),
                ),
                child: Row(
                  children: [
                    // Attachment button
                    AnimatedBuilder(
                      animation: _attachButtonScale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _attachButtonScale.value,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showAttachmentOptions,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  Icons.attach_file_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Text input
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (text) {
                          setState(() {
                            _isComposing =
                                text.isNotEmpty || _selectedFile != null;
                          });
                          if (_isComposing) {
                            _sendButtonController.forward();
                            _inputController.forward();
                          } else {
                            _sendButtonController.reverse();
                            _inputController.reverse();
                          }
                        },
                        onSubmitted: _handleSubmitted,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),

                    const SizedBox(width: 8),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Send button
          AnimatedBuilder(
            animation: _sendButtonScale,
            builder: (context, child) {
              return Transform.scale(
                scale: _sendButtonScale.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap:
                          _isComposing
                              ? () => _handleSubmitted(_textController.text)
                              : null,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Send',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Image preview for images
          if (_selectedFileType == 'image' && _selectedFile != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedFile!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),

          // File info row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(),
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getFileName(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _selectedFileType?.toUpperCase() ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _clearAttachment,
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    switch (_selectedFileType) {
      case 'image':
        return Icons.image_rounded;
      case 'audio':
        return Icons.audiotrack_rounded;
      case 'document':
        return Icons.description_rounded;
      default:
        return Icons.attach_file_rounded;
    }
  }

  String _getFileName() {
    if (_selectedFile != null) {
      return _selectedFile!.path.split('/').last;
    }
    return 'Unknown file';
  }
}
