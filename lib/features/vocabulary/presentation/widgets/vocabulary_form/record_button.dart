import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import 'tts_helper.dart';

/// A reusable button for recording and playing voice pronunciation
class RecordButton extends StatefulWidget {
  /// Word ID for the recording file name
  final String wordId;
  
  /// Existing recording path (if any)
  final String? recordingPath;
  
  /// TTS helper instance that handles recording
  final TtsHelper ttsHelper;
  
  /// Callback when a recording is saved
  final Function(String? path) onRecordingSaved;

  /// Constructor for RecordButton
  const RecordButton({
    super.key,
    required this.wordId,
    this.recordingPath,
    required this.ttsHelper,
    required this.onRecordingSaved,
  });

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> {
  bool _isRecording = false;
  String? _recordingPath;
  
  @override
  void initState() {
    super.initState();
    _recordingPath = widget.recordingPath;
  }
  
  @override
  Widget build(BuildContext context) {
    // If web, return disabled button with info tooltip
    if (kIsWeb) {
      return Tooltip(
        message: 'Recording not available on web',
        child: IconButton(
          icon: const Icon(Icons.mic_off),
          onPressed: null,
          color: Colors.grey,
        ),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Record button
        IconButton(
          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
          color: _isRecording ? Colors.red : null,
          tooltip: _isRecording ? 'Stop recording' : 'Record pronunciation',
          onPressed: _toggleRecording,
        ),
        
        // Play button (only if recording exists)
        if (_recordingPath != null)
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Play recording',
            onPressed: () {
              widget.ttsHelper.playRecording(_recordingPath);
            },
          ),
      ],
    );
  }
  
  /// Toggle recording state
  Future<void> _toggleRecording() async {
    // Get or generate a word ID
    final wordId = widget.wordId.isEmpty ? const Uuid().v4() : widget.wordId;
    
    if (_isRecording) {
      // Stop recording
      final path = await widget.ttsHelper.stopRecording();
      
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });
      
      // Notify parent
      widget.onRecordingSaved(path);
    } else {
      // Start recording
      await widget.ttsHelper.startRecording(wordId);
      
      setState(() {
        _isRecording = true;
      });
    }
  }
} 