import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unicons/unicons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../state/store.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String ghostId;
  const ChatScreen({super.key, required this.ghostId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  Timer? _recordTimer;
  int _recordDuration = 0;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _audioRecorder.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  String get _displayId => widget.ghostId.length > 16 ? "${widget.ghostId.substring(0, 6)}...${widget.ghostId.substring(widget.ghostId.length - 6)}" : widget.ghostId;

  // -- Image Logic --
  Future<void> _pickAndSendImage() async {
    final XFile? imageFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageFile == null) return;
    Uint8List imageBytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return;
    img.Image resizedImage = img.copyResize(originalImage, width: 1024);
    Uint8List resizedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
    final dest = _getDestKey();
    if (dest.isEmpty) return;
    try {
      await api.sendImage(destHex: dest, imageBytes: resizedBytes);
      ref.read(chatProvider.notifier).sync();
    } catch (e) { /* ... */ }
  }

  // -- Voice Logic --
  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      _recordingPath = '${dir.path}/temp_audio.m4a';
      await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: _recordingPath!);
      setState(() => _isRecording = true);
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordDuration++);
      });
    }
  }

  Future<void> _stopAndSendRecording() async {
    final path = await _audioRecorder.stop();
    setState(() { _isRecording = false; _recordDuration = 0; });
    _recordTimer?.cancel();
    if (path == null) return;
    
    final file = File(path);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final dest = _getDestKey();
      if (dest.isEmpty) return;
      try {
        await api.sendVoice(destHex: dest, voiceBytes: bytes);
        ref.read(chatProvider.notifier).sync();
        file.delete();
      } catch (e) { /* ... */ }
    }
  }

  Future<void> _cancelRecording() async {
    await _audioRecorder.stop();
    setState(() { _isRecording = false; _recordDuration = 0; });
    _recordTimer?.cancel();
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) file.delete();
    }
  }
  
  String _getDestKey() {
    return widget.ghostId.length == 64 ? widget.ghostId : ref.read(contactsProvider).value?.firstWhere((c) => c.alias == widget.ghostId).pubkey ?? "";
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
                  if (msg.core.text.startsWith("gossamer_image://")) {
                    final imageId = msg.core.text.replaceFirst("gossamer_image://", "");
                    return _ImageBubble(imageId: imageId, isMe: msg.core.isMe);
                  }
                  if (msg.core.text.startsWith("gossamer_voice://")) {
                    final voiceId = msg.core.text.replaceFirst("gossamer_voice://", "");
                    return _VoiceBubble(voiceId: voiceId, isMe: msg.core.isMe);
                  }
                  return _TextBubble(text: msg.core.text, isMe: msg.core.isMe, status: msg.status);
                },
              ),
            ),
            if (_isRecording) _buildRecordingOverlay(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFFFF005C).withOpacity(0.1),
      child: Row(
        children: [
          const Icon(UniconsLine.microphone, color: Color(0xFFFF005C)),
          const SizedBox(width: 16),
          Text("${_recordDuration}s", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          const Spacer(),
          Text("Slide to cancel <", style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildInputArea() {
    final hasText = _ctrl.text.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF15151F), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(icon: const Icon(UniconsLine.paperclip, color: Colors.white54), onPressed: _pickAndSendImage),
              Expanded(child: TextField(controller: _ctrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Secure Message...", fillColor: Colors.black, isDense: true))),
              const SizedBox(width: 12),
              hasText 
                ? IconButton.filled(
                    onPressed: () {
                      final dest = _getDestKey();
                      if (dest.isNotEmpty) {
                        ref.read(chatProvider.notifier).sendMessage(dest, _ctrl.text.trim());
                        _ctrl.clear();
                        HapticFeedback.lightImpact();
                      }
                    },
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                    icon: const Icon(UniconsLine.message, color: Colors.white),
                  )
                : GestureDetector(
                    onLongPress: _startRecording,
                    onLongPressEnd: (details) {
                      // Check if user slid off to cancel
                      if (details.localPosition.dx < -50) {
                        _cancelRecording();
                      } else {
                        _stopAndSendRecording();
                      }
                    },
                    child: const CircleAvatar(radius: 24, backgroundColor: Color(0xFF6C63FF), child: Icon(UniconsLine.microphone, color: Colors.white)),
                  )
            ],
          ),
        ),
      ),
    );
  }
}

// ... _TextBubble and _ImageBubble remain ...

class _VoiceBubble extends StatefulWidget {
  final String voiceId;
  final bool isMe;
  const _VoiceBubble({required this.voiceId, required this.isMe});
  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}
class _VoiceBubbleState extends State<_VoiceBubble> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Uint8List? _audioData;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) => setState(() => _playerState = s));
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _loadAudio();
  }

  Future<void> _loadAudio() async {
    try {
      final bytes = await api.getVoice(voiceId: widget.voiceId);
      setState(() => _audioData = Uint8List.fromList(bytes));
      await _player.setSource(BytesSource(_audioData!));
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_audioData == null) {
      return const SizedBox(width: 200, height: 50, child: Center(child: CircularProgressIndicator()));
    }
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(color: widget.isMe ? const Color(0xFF6C63FF) : const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            IconButton(
              icon: Icon(_playerState == PlayerState.playing ? UniconsLine.pause : UniconsLine.play, color: Colors.white),
              onPressed: () {
                if (_playerState == PlayerState.playing) {
                  _player.pause();
                } else {
                  _player.resume();
                }
              },
            ),
            Expanded(
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (_duration.inMilliseconds > 0) ? _position.inMilliseconds / _duration.inMilliseconds : 0.0,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')} / ${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}
