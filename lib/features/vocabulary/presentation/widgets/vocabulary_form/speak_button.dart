import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'tts_helper.dart';

/// A reusable button for speaking text using TTS
class SpeakButton extends StatelessWidget {
  /// The text to speak
  final String text;
  
  /// Tooltip text for the button
  final String tooltip;
  
  /// TTS helper instance
  final TtsHelper ttsHelper;

  /// Constructor for SpeakButton
  const SpeakButton({
    super.key,
    required this.text,
    required this.tooltip,
    required this.ttsHelper,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.volume_up),
      tooltip: tooltip,
      onPressed: () {
        final cleanText = text.trim();
        if (cleanText.isNotEmpty) {
          ttsHelper.speak(cleanText);
        }
      },
    );
  }
} 