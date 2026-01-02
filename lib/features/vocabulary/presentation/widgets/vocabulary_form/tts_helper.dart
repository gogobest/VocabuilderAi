import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'package:path_provider/path_provider.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:visual_vocabularies/core/utils/tts_config_service.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';

/// Helper class to handle voice recording and text-to-speech functionality
class TtsHelper {
  final BuildContext _context;
  final _audioRecorder = AudioRecorder();
  final FlutterTts _flutterTts = FlutterTts();
  final TtsConfigService _ttsConfigService = sl<TtsConfigService>();
  bool _isRecording = false;
  String? _recordedPath;
  bool _isSpeaking = false;
  bool _isTtsInitialized = false;
  List<dynamic>? _availableEngines;
  List<dynamic>? _availableLanguages;
  
  // Queue for TTS requests to prevent interruptions
  final Queue<String> _ttsQueue = Queue<String>();
  bool _isProcessingQueue = false;
  
  // Debounce mechanism
  Timer? _debounceTimer;
  String? _lastSpokenText;
  DateTime? _lastSpeakTime;
  
  // Retry control
  int _maxRetries = 4;
  Map<String, int> _retryCount = {};
  bool _isReset = false;

  /// Constructor takes a context for displaying snackbars
  TtsHelper(this._context) {
    _initTts();
  }

  /// Initialize TTS engine with proper settings
  Future<void> _initTts() async {
    try {
      // Get saved settings
      final selectedEngine = await _ttsConfigService.getSelectedEngine();
      final language = await _ttsConfigService.getLanguage();
      final rate = await _ttsConfigService.getRate();
      final pitch = await _ttsConfigService.getPitch();
      final volume = await _ttsConfigService.getVolume();
      
      // Force stop any existing speech
      await _flutterTts.stop();
      
      // Set up platform-specific settings
      if (kIsWeb) {
        // Web-specific settings
        await _flutterTts.setVolume(volume);
        await _flutterTts.setSpeechRate(rate);
        await _flutterTts.setPitch(pitch);
        
        // Web-specific error and completion handling
        _flutterTts.setStartHandler(() {
          debugPrint('TTS started on web');
          _isSpeaking = true;
        });
        
        _flutterTts.setCompletionHandler(() {
          debugPrint('TTS completed on web');
          _isSpeaking = false;
          _processNextInQueue();
        });
        
        _flutterTts.setCancelHandler(() {
          debugPrint('TTS cancelled on web');
          _isSpeaking = false;
        });
      } else if (Platform.isAndroid) {
        // Android-specific settings
        
        // Set the engine if one was selected
        if (selectedEngine != null && selectedEngine.isNotEmpty) {
          await _flutterTts.setEngine(selectedEngine);
        }
        
        // Get available engines for later use
        try {
          _availableEngines = await _flutterTts.getEngines;
          debugPrint('Available TTS Engines: $_availableEngines');
        } catch (e) {
          debugPrint('Error getting TTS engines: $e');
        }
        
        // Get available languages for the current engine
        try {
          _availableLanguages = await _flutterTts.getLanguages;
          debugPrint('Available TTS Languages: $_availableLanguages');
        } catch (e) {
          debugPrint('Error getting TTS languages: $e');
        }
        
        await _flutterTts.setVolume(volume);
        await _flutterTts.setSpeechRate(rate);
        await _flutterTts.setPitch(pitch);
        
        // Set language to the saved preference or default to English
        await _flutterTts.setLanguage(language);
        
        // Listen for completion
        _flutterTts.setCompletionHandler(() {
          debugPrint('TTS completed on Android');
          _isSpeaking = false;
          _processNextInQueue();
        });
        
        // Set progress handler
        _flutterTts.setProgressHandler(
          (String text, int start, int end, String word) {
            debugPrint('TTS progress: $word ($start->$end)');
          }
        );
      } else if (Platform.isIOS) {
        // iOS-specific settings
        await _flutterTts.setVolume(volume);
        await _flutterTts.setSpeechRate(rate);
        await _flutterTts.setPitch(pitch);
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setLanguage(language);
        
        // Listen for completion
        _flutterTts.setCompletionHandler(() {
          debugPrint('TTS completed on iOS');
          _isSpeaking = false;
          _processNextInQueue();
        });
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Desktop settings
        await _flutterTts.setVolume(volume);
        await _flutterTts.setSpeechRate(rate);
        await _flutterTts.setPitch(pitch);
        await _flutterTts.setLanguage(language);
        
        // Desktop-specific handlers
        _flutterTts.setCompletionHandler(() {
          debugPrint('TTS completed on Desktop');
          _isSpeaking = false;
          _processNextInQueue();
        });
      }
      
      // Set up listeners for all platforms
      _flutterTts.setErrorHandler((msg) {
        debugPrint("TTS error: $msg");
        
        // Handle different types of errors
        final errorMessage = msg.toString().toLowerCase();
        _isSpeaking = false;
        
        // Handle interruption specifically
        if (errorMessage.contains('interrupt')) {
          debugPrint("Handling interruption error");
          _isReset = true;
          
          // Clear current state
          _clearTtsState();
          
          // Delay before processing next queue item
          Future.delayed(const Duration(milliseconds: 500), () {
            _isReset = false;
            _processNextInQueue();
          });
        } else {
          // For other errors, try to continue with queue
          Future.delayed(const Duration(milliseconds: 300), () {
            _processNextInQueue();
          });
        }
      });
      
      // Successfully initialized
      _isTtsInitialized = true;
      debugPrint('TTS initialized successfully');
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      _isTtsInitialized = false;
    }
  }

  /// Get available TTS engines (Android only)
  Future<List<String>> getAvailableEngines() async {
    if (!Platform.isAndroid) return [];
    
    try {
      if (_availableEngines == null) {
        _availableEngines = await _flutterTts.getEngines;
      }
      
      return _availableEngines?.map((engine) => engine.toString()).toList() ?? [];
    } catch (e) {
      debugPrint('Error getting TTS engines: $e');
      return [];
    }
  }

  /// Get available languages for the current engine
  Future<List<String>> getAvailableLanguages() async {
    try {
      if (_availableLanguages == null) {
        _availableLanguages = await _flutterTts.getLanguages;
      }
      
      return _availableLanguages?.map((lang) => lang.toString()).toList() ?? [];
    } catch (e) {
      debugPrint('Error getting TTS languages: $e');
      return [];
    }
  }

  /// Set the TTS engine (Android only)
  Future<bool> setEngine(String engine) async {
    if (!Platform.isAndroid) return false;
    
    try {
      await _flutterTts.setEngine(engine);
      await _ttsConfigService.setSelectedEngine(engine);
      
      // Refresh available languages for the new engine
      try {
        _availableLanguages = await _flutterTts.getLanguages;
      } catch (e) {
        debugPrint('Error getting TTS languages for new engine: $e');
      }
      
      return true;
    } catch (e) {
      debugPrint('Error setting TTS engine: $e');
      return false;
    }
  }

  /// Set the TTS language
  Future<bool> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
      await _ttsConfigService.setLanguage(language);
      return true;
    } catch (e) {
      debugPrint('Error setting TTS language: $e');
      return false;
    }
  }

  /// Set the speech rate (0.0 to 1.0)
  Future<bool> setRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
      await _ttsConfigService.setRate(rate);
      return true;
    } catch (e) {
      debugPrint('Error setting TTS rate: $e');
      return false;
    }
  }

  /// Set the pitch (0.0 to 1.0)
  Future<bool> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
      await _ttsConfigService.setPitch(pitch);
      return true;
    } catch (e) {
      debugPrint('Error setting TTS pitch: $e');
      return false;
    }
  }

  /// Set the volume (0.0 to 1.0)
  Future<bool> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
      await _ttsConfigService.setVolume(volume);
      return true;
    } catch (e) {
      debugPrint('Error setting TTS volume: $e');
      return false;
    }
  }

  /// Get the current TTS settings
  Future<Map<String, dynamic>> getCurrentSettings() async {
    return {
      'engine': await _ttsConfigService.getSelectedEngine(),
      'language': await _ttsConfigService.getLanguage(),
      'rate': await _ttsConfigService.getRate(),
      'pitch': await _ttsConfigService.getPitch(),
      'volume': await _ttsConfigService.getVolume(),
    };
  }

  /// Check if TTS is available on this device
  Future<bool> isTtsAvailable() async {
    // If we've already successfully initialized, consider it available
    if (_isTtsInitialized) return true;
    
    try {
      // Try to set a language as a simple check if TTS is working
      await _flutterTts.setLanguage("en-US");
      return true;
    } catch (e) {
      debugPrint('Error checking TTS availability: $e');
      return false;
    }
  }

  /// Process the next item in the TTS queue
  Future<void> _processNextInQueue() async {
    // Skip processing if in reset state
    if (_isReset) {
      debugPrint('Skipping queue processing during reset');
      return;
    }
    
    // If queue is empty or already processing, exit
    if (_ttsQueue.isEmpty || _isProcessingQueue) {
      _isProcessingQueue = false;
      return;
    }
    
    _isProcessingQueue = true;
    
    try {
      // Get the next text to speak from the queue
      final text = _ttsQueue.removeFirst();
      
      // Check retry count for this text
      final retryCount = _retryCount[text] ?? 0;
      if (retryCount >= _maxRetries) {
        debugPrint('Maximum retries reached for "$text", skipping');
        _retryCount.remove(text);
        _isProcessingQueue = false;
        _processNextInQueue(); // Move to next item
        return;
      }
      
      // Make sure TTS is stopped before starting a new one
      if (_isSpeaking) {
        await _flutterTts.stop();
        // Wait for the stop to complete
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // Update retry count
      _retryCount[text] = retryCount + 1;
      
      // Show visual indicator (only on first try or after several retries)
      if (retryCount == 0 || retryCount > 1) {
        _showTextSnackbar(text);
      }
      
      // Prepare the TTS engine before speaking
      await _prepareToSpeak();
      
      // Speak the text
      _isSpeaking = true;
      
      // Start a safety timeout to ensure we don't get stuck
      _startSafetyTimeout(text);
      
      // Use different method for web
      if (kIsWeb) {
        await _flutterTts.speak(text);
      } else {
        final result = await _flutterTts.speak(text);
        if (result != 1) {
          // Speaking failed
          debugPrint('TTS speak failed with result: $result');
          _isSpeaking = false;
          
          // Wait before trying next item
          await Future.delayed(const Duration(milliseconds: 200));
          _isProcessingQueue = false;
          _processNextInQueue();
        }
      }
    } catch (e) {
      debugPrint('Error processing TTS queue: $e');
      _isSpeaking = false;
      _isProcessingQueue = false;
      
      // Try the next item after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _processNextInQueue();
      });
    }
  }
  
  /// Prepare the TTS engine before speaking
  Future<void> _prepareToSpeak() async {
    try {
      // For Android, some engines benefit from this preparation
      if (!kIsWeb && Platform.isAndroid) {
        // Get current settings and reapply them - helps "warm up" the engine
        final settings = await getCurrentSettings();
        await _flutterTts.setLanguage(settings['language'] ?? 'en-US');
        await _flutterTts.setPitch(settings['pitch'] ?? 1.0);
        await _flutterTts.setSpeechRate(settings['rate'] ?? 0.5);
      }
      
      // Brief pause to ensure engine is ready
      await Future.delayed(const Duration(milliseconds: 150));
    } catch (e) {
      debugPrint('Error preparing TTS: $e');
    }
  }

  /// Use text-to-speech to speak the provided text
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    // Reset state if needed
    if (_isReset) {
      debugPrint('TTS was reset, reinitializing');
      _isReset = false;
      _clearTtsState();
      _initTts();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Debounce mechanism - prevent rapid repeated calls with the same text
    if (_lastSpokenText == text && _lastSpeakTime != null) {
      final timeSinceLastSpeak = DateTime.now().difference(_lastSpeakTime!);
      if (timeSinceLastSpeak.inMilliseconds < 600) { // Reduced from 1000ms to 600ms
        debugPrint('Debouncing duplicate TTS request');
        
        // Show subtle feedback for debounced requests
        ScaffoldMessenger.of(_context).clearSnackBars();
        ScaffoldMessenger.of(_context).showSnackBar(
          SnackBar(
            content: Text('Already speaking: $text'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 800),
            backgroundColor: Colors.blueGrey.withOpacity(0.8),
          ),
        );
        return;
      }
    }
    
    // If we're switching to a new word, clear state and stop current speech
    if (_lastSpokenText != text) {
      // Reset retry count for new words
      _retryCount.remove(text);
      
      if (_isSpeaking) {
        await _flutterTts.stop();
        _isSpeaking = false;
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    
    _lastSpokenText = text;
    _lastSpeakTime = DateTime.now();
    
    // Cancel any pending debounce
    _debounceTimer?.cancel();
    
    try {
      // Don't add to queue if already there (duplicates)
      if (!_ttsQueue.contains(text)) {
        _ttsQueue.add(text);
      }
      
      // If we're not already processing the queue, start it
      if (!_isProcessingQueue) {
        _processNextInQueue();
      }
    } catch (e) {
      debugPrint('Error queueing text to speak: $e');
      _showSnackbar('Could not speak the text');
    }
  }
  
  /// Start recording user's voice
  Future<void> startRecording(String wordId) async {
    if (kIsWeb) {
      _showSnackbar('Recording not supported on web');
      return;
    }
    
    if (_isRecording) {
      await stopRecording();
      return;
    }
    
    try {
      // Check microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _showSnackbar('Microphone permission denied');
        return;
      }
      
      // Prepare recording directory
      final directory = await _getRecordingsDirectory();
      final path = p.join(directory.path, '$wordId.m4a');
      _recordedPath = path;
      
      // Configure recorder
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      
      _isRecording = true;
      _showSnackbar('Recording started...');
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _showSnackbar('Could not start recording');
    }
  }
  
  /// Stop the recording
  Future<String?> stopRecording() async {
    if (!_isRecording) return _recordedPath;
    
    try {
      await _audioRecorder.stop();
      _isRecording = false;
      _showSnackbar('Recording saved');
      return _recordedPath;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _showSnackbar('Error saving recording');
      return null;
    }
  }
  
  /// Play a recorded audio file
  Future<void> playRecording(String? path) async {
    if (path == null || path.isEmpty) {
      _showSnackbar('No recording available');
      return;
    }
    
    try {
      if (File(path).existsSync()) {
        // In a real implementation, we would play the audio file here
        // For now, just show a snackbar
        _showSnackbar('Playing recording...');
      } else {
        _showSnackbar('Recording not found');
      }
    } catch (e) {
      _showSnackbar('Error playing recording');
      debugPrint('Error playing recording: $e');
    }
  }
  
  /// Get or create directory for storing recordings
  Future<Directory> _getRecordingsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${appDir.path}/recordings');
    
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    
    return recordingsDir;
  }
  
  /// Display a snackbar with the text being spoken
  void _showTextSnackbar(String text) {
    ScaffoldMessenger.of(_context).clearSnackBars();
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(
        content: Text('🔊 $text'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: (text.length * 80).clamp(1500, 5000)),
      ),
    );
  }
  
  /// Display a general snackbar message
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(_context).clearSnackBars();
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Check if currently recording
  bool get isRecording => _isRecording;
  
  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;
  
  /// Get current recording path
  String? get recordedPath => _recordedPath;
  
  /// For compatibility with existing code
  bool get isInitialized => _isTtsInitialized;

  /// Clean up resources
  void dispose() {
    _flutterTts.stop();
    _debounceTimer?.cancel();
    _ttsQueue.clear();
    _retryCount.clear();
    _clearTtsState();
  }

  /// Clear TTS state when encountering errors
  void _clearTtsState() {
    _isSpeaking = false;
    _isProcessingQueue = false;
    
    // Cancel any pending timers
    _debounceTimer?.cancel();
  }

  /// Start a safety timeout to ensure TTS doesn't get stuck
  void _startSafetyTimeout(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () {
      // If we're still speaking the same text after 5 seconds, something went wrong
      if (_isSpeaking) {
        debugPrint('Safety timeout triggered for "$text"');
        _flutterTts.stop();
        _isSpeaking = false;
        _isProcessingQueue = false;
        
        // Clear any problematic state
        _clearTtsState();
        
        // Try to process next item
        Future.delayed(const Duration(milliseconds: 500), () {
          _processNextInQueue();
        });
      }
    });
  }
} 