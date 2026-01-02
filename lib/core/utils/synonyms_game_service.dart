import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';

/// Service to manage the synonyms game functionality
class SynonymsGameService {
  static const String _markedSynonymsKey = 'marked_synonyms';
  
  /// Save a marked synonym
  /// Returns true if the synonym was newly added, false if it was already marked
  Future<bool> markSynonym(String wordId, String synonym) async {
    final prefs = await SharedPreferences.getInstance();
    final markedSynonymsJson = prefs.getString(_markedSynonymsKey) ?? '{}';
    final Map<String, dynamic> markedSynonyms = json.decode(markedSynonymsJson);
    
    if (!markedSynonyms.containsKey(wordId)) {
      markedSynonyms[wordId] = [];
    }
    
    final wordSynonyms = List<String>.from(markedSynonyms[wordId]);
    if (!wordSynonyms.contains(synonym)) {
      wordSynonyms.add(synonym);
      markedSynonyms[wordId] = wordSynonyms;
      await prefs.setString(_markedSynonymsKey, json.encode(markedSynonyms));
      return true;
    }
    
    return false;
  }
  
  /// Unmark a previously marked synonym
  Future<bool> unmarkSynonym(String wordId, String synonym) async {
    final prefs = await SharedPreferences.getInstance();
    final markedSynonymsJson = prefs.getString(_markedSynonymsKey) ?? '{}';
    final Map<String, dynamic> markedSynonyms = json.decode(markedSynonymsJson);
    
    if (!markedSynonyms.containsKey(wordId)) {
      return false;
    }
    
    final wordSynonyms = List<String>.from(markedSynonyms[wordId]);
    final removed = wordSynonyms.remove(synonym);
    
    if (removed) {
      if (wordSynonyms.isEmpty) {
        markedSynonyms.remove(wordId);
      } else {
        markedSynonyms[wordId] = wordSynonyms;
      }
      await prefs.setString(_markedSynonymsKey, json.encode(markedSynonyms));
      return true;
    }
    
    return false;
  }
  
  /// Get all marked synonyms for a word
  Future<List<String>> getMarkedSynonymsForWord(String wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final markedSynonymsJson = prefs.getString(_markedSynonymsKey) ?? '{}';
    final Map<String, dynamic> markedSynonyms = json.decode(markedSynonymsJson);
    
    if (!markedSynonyms.containsKey(wordId)) {
      return [];
    }
    
    return List<String>.from(markedSynonyms[wordId]);
  }
  
  /// Check if a synonym is marked for a word
  Future<bool> isSynonymMarked(String wordId, String synonym) async {
    final markedSynonyms = await getMarkedSynonymsForWord(wordId);
    return markedSynonyms.contains(synonym);
  }
  
  /// Get all marked synonyms
  Future<Map<String, List<String>>> getAllMarkedSynonyms() async {
    final prefs = await SharedPreferences.getInstance();
    final markedSynonymsJson = prefs.getString(_markedSynonymsKey) ?? '{}';
    final Map<String, dynamic> markedSynonyms = json.decode(markedSynonymsJson);
    
    final result = <String, List<String>>{};
    
    markedSynonyms.forEach((key, value) {
      result[key] = List<String>.from(value);
    });
    
    return result;
  }
  
  /// Get all vocabulary items with marked synonyms
  /// Requires a list of all vocabulary items to match IDs with marked synonyms
  Future<List<VocabularyItem>> getVocabularyItemsWithMarkedSynonyms(
    List<VocabularyItem> allItems
  ) async {
    final markedSynonymsMap = await getAllMarkedSynonyms();
    
    return allItems.where((item) => 
      markedSynonymsMap.containsKey(item.id) && 
      markedSynonymsMap[item.id]!.isNotEmpty
    ).toList();
  }
  
  /// Reset all marked synonyms
  Future<void> resetAllMarkedSynonyms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_markedSynonymsKey);
  }
} 