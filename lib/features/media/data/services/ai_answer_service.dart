import 'package:hive/hive.dart';
import 'package:visual_vocabularies/features/media/data/models/ai_answer_model.dart';
import 'package:visual_vocabularies/features/media/domain/entities/ai_answer.dart';

class AIAnswerService {
  static const String boxName = 'ai_answers';

  // Save an AI answer to storage
  Future<bool> saveAIAnswer(AIAnswer answer) async {
    try {
      final box = await Hive.openBox<AIAnswerModel>(boxName);
      await box.put(answer.id, AIAnswerModel.fromEntity(answer));
      return true;
    } catch (e) {
      print('Error saving AI answer: $e');
      return false;
    }
  }

  // Get all saved AI answers
  Future<List<AIAnswer>> getAllAIAnswers() async {
    try {
      final box = await Hive.openBox<AIAnswerModel>(boxName);
      return box.values.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting AI answers: $e');
      return [];
    }
  }

  // Get AI answers by media source
  Future<List<AIAnswer>> getAIAnswersBySource(String mediaTitle, {int? season, int? episode}) async {
    try {
      final box = await Hive.openBox<AIAnswerModel>(boxName);
      final answers = box.values.where((answer) {
        bool match = answer.sourceMediaTitle == mediaTitle;
        
        if (season != null) {
          match = match && answer.sourceMediaSeason == season;
        }
        
        if (episode != null) {
          match = match && answer.sourceMediaEpisode == episode;
        }
        
        return match;
      }).toList();
      
      return answers.map((model) => model.toEntity()).toList();
    } catch (e) {
      print('Error getting AI answers by source: $e');
      return [];
    }
  }

  // Delete an AI answer
  Future<bool> deleteAIAnswer(String id) async {
    try {
      final box = await Hive.openBox<AIAnswerModel>(boxName);
      await box.delete(id);
      return true;
    } catch (e) {
      print('Error deleting AI answer: $e');
      return false;
    }
  }

  // Delete multiple AI answers
  Future<bool> deleteMultipleAIAnswers(List<String> ids) async {
    try {
      final box = await Hive.openBox<AIAnswerModel>(boxName);
      await box.deleteAll(ids);
      return true;
    } catch (e) {
      print('Error deleting multiple AI answers: $e');
      return false;
    }
  }

  // Get count of saved AI answers
  Future<int> getAIAnswerCount() async {
    try {
      final box = await Hive.openBox<AIAnswerModel>(boxName);
      return box.length;
    } catch (e) {
      print('Error getting AI answer count: $e');
      return 0;
    }
  }
} 