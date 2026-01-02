/// Types of prompts that can be generated
enum PromptType {
  vocabularyGeneration,
  tenseVariation,
  subtitleExtraction,
  connectionTest,
  wordListGeneration,
  emojiGeneration,
  tenseEvaluation,
  textTenseAnalysis
}

/// Class to generate prompt templates based on prompt type
class PromptTemplate {
  /// Get prompt template based on prompt type and parameters
  static Map<String, dynamic> getTemplate(PromptType type, Map<String, dynamic> parameters) {
    switch (type) {
      case PromptType.vocabularyGeneration:
        return _getVocabularyTemplate(parameters['word']);
      
      case PromptType.tenseVariation:
        return _getTenseVariationTemplate(parameters['word']);
      
      case PromptType.subtitleExtraction:
        return _getSubtitleExtractionTemplate(
          parameters['subtitleText'],
          parameters['showTitle'],
          parameters['season'],
          parameters['episode'],
          minWords: parameters['minWords'],
          maxWords: parameters['maxWords'],
          difficultyLevel: parameters['difficultyLevel']
        );
      
      case PromptType.connectionTest:
        return _getConnectionTestTemplate();
      
      case PromptType.wordListGeneration:
        return _getWordListTemplate(
          parameters['category'],
          parameters['difficulty'],
          parameters['count'],
        );
        
      case PromptType.emojiGeneration:
        return _getEmojiGenerationTemplate(
          parameters['word'],
          parameters['meaning'],
        );
        
      case PromptType.tenseEvaluation:
        return _getTenseEvaluationTemplate(
          parameters['word'],
          parameters['userAnswer'],
          parameters['tense'],
          parameters['option'],
        );
      
      case PromptType.textTenseAnalysis:
        return _getTextTenseAnalysisTemplate(parameters);
    }
  }
  
  /// Template for vocabulary generation
  static Map<String, dynamic> _getVocabularyTemplate(String word) {
    return {
      'prompt': "Generate comprehensive vocabulary information for the word '$word'. " +
               "Structure your response as a JSON object with these fields:\n" +
               "- meaning: a clear, concise definition\n" +
               "- example: a natural example sentence\n" +
               "- partOfSpeech: the grammatical part of speech (noun, verb, adjective, adverb, etc.)\n" +
               "- category: select the most appropriate logical category based on the word's meaning (e.g., Feelings/Emotions, Actions/Verbs, Animals, etc.)\n" +
               "- difficultyLevel: a number from 1-5 (1=easy, 5=hard)\n" +
               "- synonyms: array of 3-5 synonyms for this word\n" +
               "- antonyms: array of 2-3 antonyms for this word (if applicable)\n" +
               "- tprGesture: suggest one of [point_up, point_down, hands_clap, wave_hand, circle_motion, thumbs_up, thumbs_down, hand_raise, pinch, spread_fingers, fist_pound, shake_head, nod_head, shrug, heart_shape]\n" +
               "- tprDescription: describe in detail how to perform the gesture in a way that directly relates to the word's meaning\n" +
               "- emoji: a single, highly relevant emoji that best represents the meaning of the word. Do NOT use generic or default emojis like 📝, 🔤, or similar. Only use an emoji that is specific and meaningful for the word.",
      'temperature': 0.7,
      'maxTokens': 1024,
      'systemPrompt': 'You are a vocabulary tutor helping to create comprehensive vocabulary entries with Total Physical Response (TPR) gestures that enhance memory through physical movement.'
    };
  }
  
  /// Template for tense variation
  static Map<String, dynamic> _getTenseVariationTemplate(String word) {
    return {
      'prompt': "Generate different tense forms of the word '$word'. " +
               "Structure your response as a JSON object with these tenses as keys:\n" +
               "- Present Simple\n" +
               "- Past Simple\n" +
               "- Present Continuous\n" +
               "- Future Simple\n" +
               "- Present Perfect\n" +
               "- Past Continuous\n" +
               "- Past Perfect\n" +
               "- Future Continuous\n" +
               "- Future Perfect\n\n" +
               "The values should be the correct form of the word in each tense. " +
               "If the word is not a verb, provide appropriate forms or variations where possible, " +
               "or indicate with 'N/A' where a tense form is not applicable.",
      'temperature': 0.2,
      'maxTokens': 1024
    };
  }
  
  /// Template for subtitle extraction
  static Map<String, dynamic> _getSubtitleExtractionTemplate(
    String subtitleText,
    String showTitle,
    String season,
    String episode,
    {int minWords = 5, 
    int maxWords = 20, 
    int difficultyLevel = 3}
  ) {
    return {
      'prompt': "Analyze the following subtitle text from $showTitle Season $season Episode $episode and identify important vocabulary words. " +
               "Extract between $minWords and $maxWords words that would be useful for English language learners, with a target difficulty level of $difficultyLevel (on a scale of 1-5, where 1 is very easy and 5 is very hard). " +
               "For each word, provide the following information:\n" +
               "1. definition: a clear, concise definition\n" +
               "2. context: an example from the subtitle text\n" +
               "3. partOfSpeech: specify if the word is a noun, verb, adjective, adverb, etc.\n" +
               "4. difficulty: rate from 1-5 how difficult this word is for learners\n" +
               "5. emoji: a single emoji that best represents the word's meaning\n" +
               "6. synonyms: 2-3 synonyms for the word\n" +
               "7. antonyms: 1-2 antonyms for the word (if applicable)\n" +
               "8. category: select the most appropriate logical category based on the word's meaning\n" +
               "9. tenseVariations: if it's a verb, provide a JSON object with key-value pairs for different tenses (Present Simple, Past Simple, Present Continuous, etc.)\n\n" +
               "If the subtitle is too short to find many words, be creative and add a few simple words that are related to the context. " +
               "Structure your response as a JSON object with a 'vocabulary' array containing the words and a 'tenses' object tracking tense usage. " +
               "\n\nSubtitle text:\n$subtitleText",
      'temperature': 0.9,
      'maxTokens': 2048,
      'systemPrompt': 'You are a language learning assistant that helps identify vocabulary from TV show subtitles.'
    };
  }
  
  /// Template for connection test
  static Map<String, dynamic> _getConnectionTestTemplate() {
    return {
      'prompt': "Hello, can you respond with the word 'Connected' to verify the connection?",
      'temperature': 0.2,
      'maxTokens': 100
    };
  }
  
  /// Template for word list generation
  static Map<String, dynamic> _getWordListTemplate(String category, int difficulty, int count) {
    return {
      'prompt': "Generate a JSON object with a 'suggestions' array containing $count unique English vocabulary words for the category '$category' at difficulty level $difficulty (1=easy, 5=hard). Only return the JSON object, no explanation.",
      'temperature': 0.7,
      'maxTokens': 512,
      'systemPrompt': 'You are a helpful assistant for generating vocabulary word lists for language learners.'
    };
  }
  
  /// Template for emoji generation
  static Map<String, dynamic> _getEmojiGenerationTemplate(String word, String meaning) {
    return {
      'prompt': """Generate ONLY a single emoji that best represents the word or phrase: '$word'
Based on this meaning: '$meaning'

Your response must be a valid JSON object with a single key 'emoji' containing ONE emoji character.
Example JSON response: {"emoji": "🚀"}

GUIDELINES:
1. Understand the entire phrase as a whole concept.
2. Focus only on the specific meaning provided.
3. Choose the most specific and relevant emoji possible.
4. Do NOT use generic emojis like 📝, 🔤, 📌 unless absolutely necessary.
5. For abstract concepts, choose an emoji that symbolizes the core idea.

For 'throne' with meaning 'a ceremonial chair for a sovereign or royal figure', the correct emoji would be 👑

RESPOND ONLY WITH THE JSON OBJECT.""",
      'temperature': 0.5,
      'maxTokens': 150,
      'systemPrompt': 'You are a helpful assistant that selects the perfect emoji to represent a word or concept. Return ONLY valid JSON with a single emoji.'
    };
  }
  
  /// Template for tense evaluation
  static Map<String, dynamic> _getTenseEvaluationTemplate(
    String word,
    String userAnswer,
    String tense,
    String option,
  ) {
    String task;
    if (option == 'verb') {
      task = "Evaluate if '$userAnswer' is the correct form of the verb '$word' in the $tense tense";
    } else if (option == 'nonVerb') {
      task = "Evaluate if the sentence '$userAnswer' correctly uses the word '$word' in a $tense tense structure";
    } else if (option == 'phrase') {
      task = "Evaluate if '$userAnswer' correctly identifies the tense used in the phrase '$word'";
    } else {
      task = "Evaluate if '$userAnswer' correctly uses '$word' in the $tense tense";
    }
    
    return {
      'prompt': "$task. Provide a comprehensive evaluation in JSON format with the following structure:\n\n" +
                "{\n" +
                "  \"isCorrect\": boolean,\n" +
                "  \"tense\": \"string\",\n" +
                "  \"verbForm\": \"string\",\n" +
                "  \"grammaticalCorrection\": \"string\",\n" +
                "  \"example\": \"string\",\n" +
                "  \"learningAdvice\": \"string\",\n" +
                "  \"score\": number\n" +
                "}\n\n" +
                "Word/phrase to evaluate: '$word'\n" +
                "User's answer: '$userAnswer'\n" +
                "Expected tense: $tense\n" +
                "Option type: $option\n\n" +
                "Guidelines for each field:\n" +
                "- isCorrect: true if the answer is correct, false otherwise\n" +
                "- tense: The tense being used (e.g., 'Present Simple', 'Past Continuous')\n" +
                "- verbForm: The correct form of the verb in the given tense\n" +
                "- grammaticalCorrection: If incorrect, explain the grammatical error and how to fix it\n" +
                "- example: Provide a clear, simple example using the word/phrase in the correct tense\n" +
                "- learningAdvice: Give a specific tip for learning this tense with this word/phrase\n" +
                "- score: A number between 0-100 based on accuracy and effort\n\n" +
                "For Past Simple evaluation:\n" +
                "- If the user used 'rode' for 'ride' - correct\n" +
                "- If the user used 'led' for 'lead' - correct\n" +
                "- If the user used 'emerged' for 'emerge' - correct\n" +
                "- Forms like 'rided', 'leaded', or using -ing forms in Past Simple are wrong\n" +
                "- Check for the presence of the exact word 'tunnel' in sentences with this word\n\n" +
                "Remember these common irregular past forms:\n" +
                "- go → went\n" + 
                "- be → was/were\n" + 
                "- do → did\n" + 
                "- say → said\n" + 
                "- make → made\n" + 
                "- take → took\n" +
                "- see → saw\n" +
                "- come → came\n" +
                "- know → knew\n" +
                "- think → thought\n\n" +
                "Be specific about the verb forms needed. Check if the user answer makes logical sense.",
      'temperature': 0.3,
      'maxTokens': 1000,
      'systemPrompt': 'You are an English language teacher specialized in grammar and verb tense evaluation. Your task is to evaluate if students use the correct tense forms in their answers. Provide detailed, constructive feedback that helps students learn from their mistakes. Be precise but fair in your grading. Remember, with phrases like "beard leads the way", the past tense should be "beard led the way". For non-verbs, check if the sentence structure correctly reflects the requested tense.'
    };
  }
  
  /// Template for text tense analysis
  static Map<String, dynamic> _getTextTenseAnalysisTemplate(Map<String, dynamic> parameters) {
    final text = parameters['text'] as String;
    final contextText = parameters['contextText'] as String?;
    final tense = parameters['tense'] as String?;
    
    String template = '''
You are an expert English teacher specializing in grammar and verb tenses. Analyze the following text for its tense usage:

TEXT: "$text"
''';

    if (contextText != null && contextText.isNotEmpty) {
      template += '''
      
CONTEXT: "$contextText"
''';
    }

    if (tense != null && tense.isNotEmpty) {
      template += '''
      
FOCUS TENSE: $tense
''';
    }

    template += '''

Provide a comprehensive but concise analysis of the tense usage in the text. Structure your response as a JSON object with these fields:
- isCorrect: Boolean value (always true for analysis, not evaluation)
- tense: The main tense used in the text or the specific tense being analyzed
- verbForm: The specific verb form(s) used in the text
- grammaticalCorrection: Any corrections or alternatives, if applicable (empty string if no corrections needed)
- example: An example sentence using the same tense properly
- learningAdvice: Brief advice about using this tense effectively
- score: A score from 0-100 (use 75 as default for informational analysis)

Your response should only contain the JSON object. Do not include any other text.
''';

    return {
      'prompt': template,
      'temperature': 0.3,
      'maxTokens': 1000,
      'systemPrompt': 'You are an expert English teacher specializing in grammar and verb tenses. Analyze the following text for its tense usage.'
    };
  }
} 