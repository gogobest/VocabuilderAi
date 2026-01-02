import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';

/// Service to manage the tenses game functionality
class TensesGameService {
  static const String _markedTensesWordsKey = 'marked_tenses_words';
  
  /// Save a marked word for tenses game
  /// Returns true if the word was newly marked, false if it was already marked
  Future<bool> markWordForTenses(String wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final markedWordsJson = prefs.getString(_markedTensesWordsKey) ?? '[]';
    final List<dynamic> markedWords = json.decode(markedWordsJson);
    
    if (!markedWords.contains(wordId)) {
      markedWords.add(wordId);
      await prefs.setString(_markedTensesWordsKey, json.encode(markedWords));
      return true;
    }
    
    return false;
  }
  
  /// Unmark a previously marked word
  Future<bool> unmarkWordForTenses(String wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final markedWordsJson = prefs.getString(_markedTensesWordsKey) ?? '[]';
    final List<dynamic> markedWords = json.decode(markedWordsJson);
    
    final removed = markedWords.remove(wordId);
    
    if (removed) {
      await prefs.setString(_markedTensesWordsKey, json.encode(markedWords));
      return true;
    }
    
    return false;
  }
  
  /// Check if a word is marked for tenses
  Future<bool> isWordMarkedForTenses(String wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final markedWordsJson = prefs.getString(_markedTensesWordsKey) ?? '[]';
    final List<dynamic> markedWords = json.decode(markedWordsJson);
    
    return markedWords.contains(wordId);
  }
  
  /// Get all vocabulary items marked for tenses game
  Future<List<VocabularyItem>> getVocabularyItemsForTensesGame(
    List<VocabularyItem> allItems
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final markedWordsJson = prefs.getString(_markedTensesWordsKey) ?? '[]';
    final List<dynamic> markedWords = json.decode(markedWordsJson);
    
    return allItems.where((item) => markedWords.contains(item.id)).toList();
  }
  
  /// Get non-verb vocabulary items marked for tenses
  Future<List<VocabularyItem>> getNonVerbItemsForTensesGame(
    List<VocabularyItem> allItems
  ) async {
    final markedItems = await getVocabularyItemsForTensesGame(allItems);
    
    return markedItems.where((item) {
      // If part of speech is explicitly set, check if it's not a verb
      if (item.partOfSpeech != null && item.partOfSpeech!.isNotEmpty) {
        final pos = item.partOfSpeech!.toLowerCase();
        // Check common non-verb parts of speech
        return pos.contains('noun') || 
               pos.contains('adjective') || 
               pos.contains('adverb') || 
               pos.contains('pronoun') || 
               pos.contains('preposition') || 
               pos.contains('conjunction') || 
               pos.contains('interjection') ||
               (pos != 'verb' && !pos.contains('verb'));
      }
      
      // If no part of speech, assume it's a non-verb if it doesn't look like a typical verb
      final word = item.word.toLowerCase();
      // Check if word doesn't end with typical verb endings
      return !word.endsWith('ing') && 
             !word.endsWith('ed') && 
             !word.endsWith('ize') && 
             !word.endsWith('ise') && 
             !word.endsWith('ate') &&
             !word.endsWith('ify');
    }).toList();
  }
  
  /// Get verb vocabulary items marked for tenses
  Future<List<VocabularyItem>> getVerbItemsForTensesGame(
    List<VocabularyItem> allItems
  ) async {
    final markedItems = await getVocabularyItemsForTensesGame(allItems);
    
    return markedItems.where((item) {
      // If part of speech is explicitly set, check if it's a verb
      if (item.partOfSpeech != null && item.partOfSpeech!.isNotEmpty) {
        final pos = item.partOfSpeech!.toLowerCase();
        return pos == 'verb' || pos.contains('verb');
      }
      
      // If no part of speech, try to detect if it's a verb based on common verb patterns
      final word = item.word.toLowerCase();
      // Check for common verb endings or patterns
      return word.endsWith('ing') || 
             word.endsWith('ed') || 
             word.endsWith('ize') || 
             word.endsWith('ise') || 
             word.endsWith('ate') ||
             word.endsWith('ify');
    }).toList();
  }
  
  /// Get phrases marked for tenses
  Future<List<VocabularyItem>> getPhrasesForTensesGame(
    List<VocabularyItem> allItems
  ) async {
    final markedItems = await getVocabularyItemsForTensesGame(allItems);
    
    return markedItems.where((item) => 
      // Consider it a phrase if:
      item.word.contains(' ') || // Has space, likely a phrase
      item.word.contains('-') || // Has hyphen, could be a phrasal verb or compound
      item.word.contains('_') || // Has underscore, could be a phrase in some format
      (item.partOfSpeech?.toLowerCase().contains('phrase') ?? false) || // Tagged as phrase
      (item.partOfSpeech?.toLowerCase().contains('expression') ?? false) || // Tagged as expression
      (item.partOfSpeech?.toLowerCase().contains('idiom') ?? false) || // Tagged as idiom
      // Check if meaning suggests it's a phrase
      (item.meaning.toLowerCase().contains('expression')) ||
      (item.meaning.toLowerCase().contains('phrase')) ||
      (item.meaning.toLowerCase().contains('idiom'))
    ).toList();
  }
  
  /// Get all marked words IDs
  Future<List<String>> getAllMarkedTensesWordsIds() async {
    final prefs = await SharedPreferences.getInstance();
    final markedWordsJson = prefs.getString(_markedTensesWordsKey) ?? '[]';
    final List<dynamic> markedWords = json.decode(markedWordsJson);
    
    return markedWords.cast<String>().toList();
  }
  
  /// Reset all marked tenses words
  Future<void> resetAllMarkedTensesWords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_markedTensesWordsKey);
  }
} 