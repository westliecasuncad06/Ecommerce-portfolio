import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

typedef OnSendText = Future<void> Function(String text);
typedef OnSendImage = Future<void> Function(XFile file);

class ChatInput extends StatefulWidget {
  final OnSendText onSendText;
  final OnSendImage onSendImage;

  const ChatInput({super.key, required this.onSendText, required this.onSendImage});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  void _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    await widget.onSendText(text);
    _ctrl.clear();
    setState(() => _sending = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (file != null) {
      await widget.onSendImage(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          children: [
            IconButton(
              onPressed: _pickImage,
              icon: Icon(Icons.photo, color: Theme.of(context).colorScheme.primary),
            ),
            Expanded(
              child: TextField(
                controller: _ctrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Write a message...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            IconButton(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                  : Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
