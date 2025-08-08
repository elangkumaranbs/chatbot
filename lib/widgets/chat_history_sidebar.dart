import 'package:flutter/material.dart';
import '../services/chat_history_service.dart';

class ChatHistorySidebar extends StatefulWidget {
  final Function(String?) onSessionSelected;
  final Function() onNewChat;
  final String? currentSessionId;

  const ChatHistorySidebar({
    Key? key,
    required this.onSessionSelected,
    required this.onNewChat,
    this.currentSessionId,
  }) : super(key: key);

  @override
  State<ChatHistorySidebar> createState() => _ChatHistorySidebarState();
}

class _ChatHistorySidebarState extends State<ChatHistorySidebar> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await ChatHistoryService.loadChatSessions();
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading sessions: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      await ChatHistoryService.deleteChatSession(sessionId);
      await _loadSessions();

      // If deleted session was current, start new chat
      if (widget.currentSessionId == sessionId) {
        widget.onNewChat();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              'Clear All History',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to delete all chat history? This cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete All'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await ChatHistoryService.clearAllHistory();
        await _loadSessions();
        widget.onNewChat();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All chat history cleared'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0D47A1).withOpacity(0.95),
            const Color(0xFF1565C0).withOpacity(0.95),
            const Color(0xFF1976D2).withOpacity(0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Chat History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // New Chat Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onNewChat,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sessions List
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : _sessions.isEmpty
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No chat history yet.\nStart a new conversation!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        final isSelected =
                            widget.currentSessionId == session['id'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            gradient:
                                isSelected
                                    ? LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.1),
                                      ],
                                    )
                                    : null,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                isSelected
                                    ? Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    )
                                    : null,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(
                              session['title'] ?? 'Untitled Chat',
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.white70,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              _formatTimestamp(session['timestamp']),
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.white70
                                        : Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color:
                                    isSelected ? Colors.white : Colors.white54,
                                size: 18,
                              ),
                              color: const Color(0xFF2D2D2D),
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _deleteSession(session['id']);
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                            ),
                            onTap:
                                () => widget.onSessionSelected(session['id']),
                          ),
                        );
                      },
                    ),
          ),

          // Footer Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _sessions.isNotEmpty ? _clearAllHistory : null,
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      _sessions.isNotEmpty ? Colors.red.shade300 : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        return 'Today $hour:$minute';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
