import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../providers/chat_provider.dart';
import '../widgets/enhanced_message_bubble.dart';
import '../widgets/enhanced_chat_input.dart';
import '../widgets/simple_welcome_screen.dart';
import '../widgets/chat_history_sidebar.dart';

class ChatScreenWithSidebar extends StatefulWidget {
  const ChatScreenWithSidebar({super.key});

  @override
  State<ChatScreenWithSidebar> createState() => _ChatScreenWithSidebarState();
}

class _ChatScreenWithSidebarState extends State<ChatScreenWithSidebar> {
  bool _sidebarVisible = false;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    // Set up auto-save timer (every 30 seconds)
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      context.read<ChatProvider>().autoSave();
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarVisible = !_sidebarVisible;
    });
  }

  void _onSessionSelected(String? sessionId) {
    if (sessionId != null) {
      context.read<ChatProvider>().loadSession(sessionId);
    }
    setState(() {
      _sidebarVisible = false; // Close sidebar on mobile
    });
  }

  void _onNewChat() {
    context.read<ChatProvider>().startNewSession();
    setState(() {
      _sidebarVisible = false; // Close sidebar on mobile
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar
              if (_sidebarVisible || isDesktop)
                ChatHistorySidebar(
                  onSessionSelected: _onSessionSelected,
                  onNewChat: _onNewChat,
                  currentSessionId:
                      context.watch<ChatProvider>().currentSessionId,
                ),

              // Main Chat Area
              Expanded(
                child: Column(
                  children: [
                    // App Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF0D47A1),
                            const Color(0xFF1565C0),
                            const Color(0xFF1976D2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            // Sidebar toggle (mobile only)
                            if (!isDesktop)
                              IconButton(
                                icon: const Icon(
                                  Icons.menu,
                                  color: Colors.white,
                                ),
                                onPressed: _toggleSidebar,
                              ),

                            // Title
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.3),
                                          Colors.white.withOpacity(0.1),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.smart_toy,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'AI Assistant',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Actions
                            Row(
                              children: [
                                // Save chat button
                                Consumer<ChatProvider>(
                                  builder: (context, provider, _) {
                                    return IconButton(
                                      icon: Icon(
                                        provider.hasUnsavedChanges
                                            ? Icons.save
                                            : Icons.save_outlined,
                                        color:
                                            provider.hasUnsavedChanges
                                                ? Colors.yellow
                                                : Colors.white54,
                                      ),
                                      onPressed:
                                          provider.messages.isNotEmpty
                                              ? () async {
                                                await provider
                                                    .saveCurrentSession();
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Chat saved!',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                              : null,
                                      tooltip: 'Save Chat',
                                    );
                                  },
                                ),

                                // Clear chat button
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (ctx) => AlertDialog(
                                            backgroundColor: const Color(
                                              0xFF1E1E1E,
                                            ),
                                            title: const Text(
                                              'Clear Chat',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            content: const Text(
                                              'Are you sure you want to clear the current chat?',
                                              style: TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(ctx),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  _onNewChat();
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
                                                child: const Text('Clear'),
                                              ),
                                            ],
                                          ),
                                    );
                                  },
                                  tooltip: 'Clear Chat',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Chat content
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF0D1421),
                              const Color(0xFF1A1A2E).withOpacity(0.95),
                              const Color(0xFF16213E).withOpacity(0.9),
                            ],
                          ),
                        ),
                        child: Consumer<ChatProvider>(
                          builder: (context, chatProvider, child) {
                            return Column(
                              children: [
                                Expanded(
                                  child:
                                      chatProvider.messages.isEmpty
                                          ? const SimpleWelcomeScreen()
                                          : ListView.builder(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 20,
                                            ),
                                            itemCount:
                                                chatProvider.messages.length,
                                            itemBuilder: (context, index) {
                                              return MessageBubble(
                                                message:
                                                    chatProvider
                                                        .messages[index],
                                              );
                                            },
                                          ),
                                ),

                                // Loading indicator
                                if (chatProvider.isLoading)
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        SpinKitThreeBounce(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'AI is thinking...',
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Chat input
                                const EnhancedChatInput(),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Mobile overlay for sidebar
          if (_sidebarVisible && !isDesktop)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _sidebarVisible = false),
                child: Container(color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }
}
