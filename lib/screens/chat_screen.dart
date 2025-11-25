import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicons/unicons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../state/store.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String ghostId;
  const ChatScreen({super.key, required this.ghostId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  Timer? _typingTimer;
  bool _isMeTyping = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_handleTyping);
    
    // Listen to live events and update typing status
    ref.listenManual(eventStreamProvider, (prev, next) {
      if (next.hasValue) {
        try {
          final event = jsonDecode(next.value!);
          if (event is List && event[0] == "EVENT") {
            final content = jsonDecode(event[2]['content']);
            if (content['type'] == 'typing_status') {
              final sender = content['sender'] as String;
              final isTyping = content['is_typing'] as bool;
              
              ref.read(typingStatusProvider.notifier).update((state) {
                return {...state, sender: isTyping};
              });
            }
          }
        } catch (e) { /* Ignore parse errors */ }
      }
    });
  }
  
  void _handleTyping() {
    if (!_isMeTyping) {
      // Send "start typing" event
      _isMeTyping = true;
      api.sendTypingStatus(destHex: _getDestKey(), isTyping: true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      // Send "stop typing" event
      _isMeTyping = false;
      api.sendTypingStatus(destHex: _getDestKey(), isTyping: false);
    });
  }
  
  String _getDestKey() {
    // Logic to resolve alias to Hex Key
    return widget.ghostId; // Simplified for this example
  }

  @override
  void dispose() {
    _ctrl.removeListener(_handleTyping);
    _typingTimer?.cancel();
    // Send one last "stop typing" message
    if (_isMeTyping) api.sendTypingStatus(destHex: _getDestKey(), isTyping: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(chatProvider); // Simplified: show all messages
    final typingMap = ref.watch(typingStatusProvider);
    final isPeerTyping = typingMap[widget.ghostId] ?? false;
    
    return Scaffold(
      backgroundColor: const Color(0xFF050507),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15151F),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.ghostId, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            // Live Typing Indicator
            if (isPeerTyping)
              const Text("typing...", style: TextStyle(fontSize: 10, color: Color(0xFF00F0FF), fontStyle: FontStyle.italic))
                 .animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 500.ms).fadeOut(delay: 500.ms)
            else
              const Text("Secure Channel", style: TextStyle(fontSize: 10, color: Colors.white54, letterSpacing: 1)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Message List...
          Expanded(child: ListView.builder(itemCount: thread.length, itemBuilder: (c,i) => Text(thread[i].text, style: const TextStyle(color: Colors.white)))),
          
          // Input Area
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _ctrl, style: const TextStyle(color: Colors.white))),
                IconButton.filled(
                  onPressed: () {
                    // Send logic
                  },
                  icon: const Icon(UniconsLine.message),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
