class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imageUrl; // For image attachments
  final String? fileUrl; // For other file types
  final String? fileType; // Type of file (image, document, audio)
  final String? fileName; // Original file name

  Message({
    required this.text,
    required this.isUser,
    this.imageUrl, // Optional image URL
    this.fileUrl, // Optional file URL
    this.fileType, // Optional file type
    this.fileName, // Optional file name
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Convert Message to Map for storage
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileName': fileName,
    };
  }

  // Create Message from Map
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'],
      isUser: json['isUser'],
      imageUrl: json['imageUrl'],
      fileUrl: json['fileUrl'],
      fileType: json['fileType'],
      fileName: json['fileName'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
