import 'package:flutter/foundation.dart';

/// A service to track user activity in the app
class TrackingService {
  static final TrackingService _instance = TrackingService._internal();
  
  /// Singleton instance
  factory TrackingService() => _instance;
  
  TrackingService._internal();
  
  /// Tracks a user action with a descriptive message
  void trackEvent(String action, {Map<String, dynamic>? data}) {
    final timestamp = DateTime.now().toString();
    final dataStr = data != null ? ', data: $data' : '';
    
    debugPrint('🔍 USER ACTION [$timestamp]: $action$dataStr');
  }
  
  /// Tracks page navigation
  void trackNavigation(String destination) {
    trackEvent('Navigation: $destination');
  }
  
  /// Tracks screen views
  void trackScreenView(String screenName, {Map<String, dynamic>? parameters}) {
    trackEvent('Screen View: $screenName', data: parameters);
  }
  
  /// Tracks button clicks
  void trackButtonClick(String buttonName, {String? screen}) {
    final location = screen != null ? ' on $screen' : '';
    trackEvent('Button Click: $buttonName$location');
  }
  
  /// Tracks form interactions
  void trackFormInteraction(String formElement, String action, {String? screen}) {
    final location = screen != null ? ' on $screen' : '';
    trackEvent('Form Interaction: $formElement, action: $action$location');
  }
  
  /// Tracks swipe actions
  void trackSwipe(String direction, {String? context}) {
    final contextStr = context != null ? ' in $context' : '';
    trackEvent('Swipe: $direction$contextStr');
  }
  
  /// Tracks item selection
  void trackSelection(String item, String category, {String? screen}) {
    final location = screen != null ? ' on $screen' : '';
    trackEvent('Selection: $item in category $category$location');
  }
  
  /// Tracks flashcard interactions
  void trackFlashcardInteraction(String action, {String? cardId, String? word}) {
    final itemInfo = word != null ? ' word: $word' : (cardId != null ? ' card: $cardId' : '');
    trackEvent('Flashcard: $action$itemInfo');
  }
  
  /// Tracks vocabulary item interactions
  void trackVocabularyInteraction(String action, {String? itemId, String? word}) {
    final itemInfo = word != null ? ' word: $word' : (itemId != null ? ' item: $itemId' : '');
    trackEvent('Vocabulary: $action$itemInfo');
  }
  
  /// Tracks settings changes
  void trackSettingsChange(String setting, dynamic oldValue, dynamic newValue) {
    trackEvent('Settings Change: $setting', data: {'from': oldValue, 'to': newValue});
  }
  
  /// Track a game action
  void trackGameAction(String action, Map<String, dynamic> properties) {
    debugPrint('Game Action: $action with properties: $properties');
    // Implement actual tracking here
  }
} 