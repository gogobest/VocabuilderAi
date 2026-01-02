import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visual_vocabularies/features/vocabulary/domain/entities/vocabulary_item.dart';

/// Service to manage the antonyms game functionality
class AntonymsGameService {
  static const String _markedAntonymsKey = 'marked_antonyms';
  
  /// Save a marked antonym
  /// Returns true if the antonym was newly added, false if it was already marked
  Future<bool> markAntonym(String wordId, String antonym) async {
    final prefs = await SharedPreferences.getInstance();
    final markedAntonymsJson = prefs.getString(_markedAntonymsKey) ?? '{}';
    final Map<String, dynamic> markedAntonyms = json.decode(markedAntonymsJson);
    
    if (!markedAntonyms.containsKey(wordId)) {
      markedAntonyms[wordId] = [];
    }
    
    final wordAntonyms = List<String>.from(markedAntonyms[wordId]);
    if (!wordAntonyms.contains(antonym)) {
      wordAntonyms.add(antonym);
      markedAntonyms[wordId] = wordAntonyms;
      await prefs.setString(_markedAntonymsKey, json.encode(markedAntonyms));
      return true;
    }
    
    return false;
  }
  
  /// Unmark a previously marked antonym
  Future<bool> unmarkAntonym(String wordId, String antonym) async {
    final prefs = await SharedPreferences.getInstance();
    final markedAntonymsJson = prefs.getString(_markedAntonymsKey) ?? '{}';
    final Map<String, dynamic> markedAntonyms = json.decode(markedAntonymsJson);
    
    if (!markedAntonyms.containsKey(wordId)) {
      return false;
    }
    
    final wordAntonyms = List<String>.from(markedAntonyms[wordId]);
    final removed = wordAntonyms.remove(antonym);
    
    if (removed) {
      if (wordAntonyms.isEmpty) {
        markedAntonyms.remove(wordId);
      } else {
        markedAntonyms[wordId] = wordAntonyms;
      }
      await prefs.setString(_markedAntonymsKey, json.encode(markedAntonyms));
      return true;
    }
    
    return false;
  }
  
  /// Get all marked antonyms for a word
  Future<List<String>> getMarkedAntonymsForWord(String wordId) async {
    final prefs = await SharedPreferences.getInstance();
    final markedAntonymsJson = prefs.getString(_markedAntonymsKey) ?? '{}';
    final Map<String, dynamic> markedAntonyms = json.decode(markedAntonymsJson);
    
    if (!markedAntonyms.containsKey(wordId)) {
      return [];
    }
    
    return List<String>.from(markedAntonyms[wordId]);
  }
  
  /// Check if an antonym is marked for a word
  Future<bool> isAntonymMarked(String wordId, String antonym) async {
    final markedAntonyms = await getMarkedAntonymsForWord(wordId);
    return markedAntonyms.contains(antonym);
  }
  
  /// Get all marked antonyms
  Future<Map<String, List<String>>> getAllMarkedAntonyms() async {
    final prefs = await SharedPreferences.getInstance();
    final markedAntonymsJson = prefs.getString(_markedAntonymsKey) ?? '{}';
    final Map<String, dynamic> markedAntonyms = json.decode(markedAntonymsJson);
    
    final result = <String, List<String>>{};
    
    markedAntonyms.forEach((key, value) {
      result[key] = List<String>.from(value);
    });
    
    return result;
  }
  
  /// Get all vocabulary items with marked antonyms
  /// Requires a list of all vocabulary items to match IDs with marked antonyms
  Future<List<VocabularyItem>> getVocabularyItemsWithMarkedAntonyms(
    List<VocabularyItem> allItems
  ) async {
    final markedAntonymsMap = await getAllMarkedAntonyms();
    
    return allItems.where((item) => 
      markedAntonymsMap.containsKey(item.id) && 
      markedAntonymsMap[item.id]!.isNotEmpty
    ).toList();
  }
  
  /// Reset all marked antonyms
  Future<void> resetAllMarkedAntonyms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_markedAntonymsKey);
  }
} 