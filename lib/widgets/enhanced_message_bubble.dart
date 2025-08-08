import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class MessageBubble extends StatefulWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message copied to clipboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    // Check if it's a local file path or network URL
    final bool isLocalFile =
        !imageUrl.startsWith('http') && !imageUrl.startsWith('data:');

    if (isLocalFile) {
      // For local files, use Image.file
      final file = File(imageUrl);
      return Image.file(
        file,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.white54, size: 32),
                  SizedBox(height: 4),
                  Text(
                    'Image not found',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // For network URLs, use Image.network
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white54, size: 32),
                  SizedBox(height: 4),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildFileAttachment() {
    if (widget.message.fileUrl == null || widget.message.fileType == null) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color color;
    String fileName = widget.message.fileName ?? 'Unknown file';

    switch (widget.message.fileType) {
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
                  widget.message.fileType!.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    final timeFormat = DateFormat('h:mm a');
    final formattedTime = timeFormat.format(widget.message.timestamp);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: GestureDetector(
                onLongPress: () => _copyToClipboard(widget.message.text),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient:
                        isUser
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
                                const Color(0xFF1A1A1A),
                                const Color(0xFF2A2A2A),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isUser ? 24 : 8),
                      topRight: Radius.circular(isUser ? 8 : 24),
                      bottomLeft: const Radius.circular(24),
                      bottomRight: const Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isUser
                                ? Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.4)
                                : Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI Assistant label
                        if (!isUser)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.3),
                                        Theme.of(context).colorScheme.secondary
                                            .withOpacity(0.3),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.psychology_rounded,
                                    size: 14,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Assistant',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Image if present
                        if (widget.message.imageUrl != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImageWidget(
                                widget.message.imageUrl!,
                              ),
                            ),
                          ),

                        // File attachment if present
                        if (widget.message.fileUrl != null &&
                            widget.message.fileType != 'image')
                          _buildFileAttachment(),

                        // Message text
                        if (widget.message.text.isNotEmpty)
                          Text(
                            widget.message.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),

                        const SizedBox(height: 8),

                        // Timestamp
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            formattedTime,
                            style: TextStyle(
                              color:
                                  isUser
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.white.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
