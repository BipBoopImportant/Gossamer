import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicons/unicons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../state/store.dart';
import '../bridge_generated.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String ghostId;
  const ChatScreen({super.key, required this.ghostId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  
  String get _displayId {
    if (widget.ghostId.length > 16) {
      return "${widget.ghostId.substring(0, 6)}...${widget.ghostId.substring(widget.ghostId.length - 6)}";
    }
    return widget.ghostId;
  }
  
  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final XFile? imageFile = await picker.pickImage(source: ImageSource.gallery);
    if (imageFile == null) return;
    
    // Read and resize
    Uint8List imageBytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return;

    img.Image resizedImage = img.copyResize(originalImage, width: 1024);
    Uint8List resizedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
    
    // Get dest key
    String dest = widget.ghostId.length == 64 ? widget.ghostId : ref.read(contactsProvider).value?.firstWhere((c) => c.alias == widget.ghostId).pubkey ?? "";
    if (dest.isEmpty) return;

    // Call Rust to send chunks
    try {
      await api.sendImage(destHex: dest, imageBytes: resizedBytes);
      ref.read(chatProvider.notifier).sync(); // Refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image send failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(chatProvider).where((m) => m.core.sender == widget.ghostId || m.core.isMe).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF050507),
        appBar: AppBar(
          backgroundColor: const Color(0xFF15151F),
          leading: IconButton(icon: const Icon(UniconsLine.arrow_left), onPressed: () => Navigator.pop(context)),
          title: Text(_displayId, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(20),
                itemCount: thread.length,
                itemBuilder: (context, index) {
                  final msg = thread[index];
                  // Check if it's an image placeholder
                  if (msg.core.text.startsWith("gossamer_image://")) {
                    final imageId = msg.core.text.replaceFirst("gossamer_image://", "");
                    return _ImageBubble(imageId: imageId, isMe: msg.core.isMe);
                  }
                  // Regular text bubble
                  return _TextBubble(text: msg.core.text, isMe: msg.core.isMe, status: msg.status);
                },
              ),
            ),
            // Input Area
            Container(
              decoration: BoxDecoration(color: const Color(0xFF15151F), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Attach Button
                      IconButton(icon: const Icon(UniconsLine.paperclip, color: Colors.white54), onPressed: _pickAndSendImage),
                      Expanded(child: TextField(controller: _ctrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Secure Message...", fillColor: Colors.black, isDense: true))),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: () {
                          if (_ctrl.text.trim().isNotEmpty) {
                            String dest = widget.ghostId.length == 64 ? widget.ghostId : ref.read(contactsProvider).value?.firstWhere((c) => c.alias == widget.ghostId).pubkey ?? "";
                            if (dest.isEmpty) return;
                            ref.read(chatProvider.notifier).sendMessage(dest, _ctrl.text.trim());
                            _ctrl.clear();
                            HapticFeedback.lightImpact();
                          }
                        },
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                        icon: const Icon(UniconsLine.message, color: Colors.white),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final MessageStatus status;
  const _TextBubble({required this.text, required this.isMe, required this.status});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(color: isMe ? const Color(0xFF6C63FF) : const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Flexible(child: Text(text, style: const TextStyle(color: Colors.white))), if (isMe) ...[const SizedBox(width: 8), _buildStatusIcon(status)]]),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }
  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending: return const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54));
      case MessageStatus.sent: return const Icon(UniconsLine.check, size: 16, color: Colors.white54);
      case MessageStatus.failed: return const Icon(UniconsLine.exclamation_triangle, size: 16, color: Colors.redAccent);
    }
  }
}

class _ImageBubble extends StatelessWidget {
  final String imageId;
  final bool isMe;
  const _ImageBubble({required this.imageId, required this.isMe});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FutureBuilder<Uint8List>(
            future: api.getImage(imageId: imageId).then((bytes) => Uint8List.fromList(bytes)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(width: 200, height: 200, child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))));
              }
              if (snapshot.hasData) {
                return Image.memory(snapshot.data!);
              }
              return const SizedBox(width: 200, height: 200, child: Center(child: Icon(UniconsLine.image_broken, color: Colors.redAccent)));
            },
          ),
        ),
      ),
    ).animate().fadeIn();
  }
}
