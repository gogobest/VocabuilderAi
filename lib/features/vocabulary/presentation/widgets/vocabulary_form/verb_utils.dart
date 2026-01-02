/// Utility class for generating various verb forms and tenses
class VerbUtils {
  /// Generate the past tense form of a verb
  String generatePastTense(String verb) {
    if (verb.isEmpty) return '';
    
    // Handle common irregular verbs
    const Map<String, String> irregularVerbs = {
      'go': 'went', 
      'have': 'had', 
      'be': 'was/were', 
      'do': 'did',
      'say': 'said', 
      'make': 'made', 
      'get': 'got', 
      'know': 'knew',
      'take': 'took', 
      'see': 'saw', 
      'come': 'came', 
      'think': 'thought',
      'look': 'looked', 
      'want': 'wanted', 
      'give': 'gave', 
      'use': 'used',
      'find': 'found', 
      'tell': 'told', 
      'ask': 'asked', 
      'work': 'worked',
      'seem': 'seemed', 
      'feel': 'felt', 
      'try': 'tried', 
      'leave': 'left',
      'call': 'called',
      'am': 'was',
      'are': 'were',
      'is': 'was',
    };
    
    if (irregularVerbs.containsKey(verb.toLowerCase())) {
      return irregularVerbs[verb.toLowerCase()]!;
    }
    
    // Apply regular past tense rules
    if (verb.endsWith('e')) {
      return verb + 'd';
    } else if (verb.endsWith('y') && !_isVowel(verb[verb.length - 2])) {
      return verb.substring(0, verb.length - 1) + 'ied';
    } else if (_endsWithConsonantVowelConsonant(verb)) {
      return verb + verb[verb.length - 1] + 'ed';
    } else {
      return verb + 'ed';
    }
  }
  
  /// Generate the present continuous form of a verb
  String generatePresentContinuous(String verb) {
    if (verb.isEmpty) return '';
    
    if (verb.endsWith('e') && !verb.endsWith('ee')) {
      return verb.substring(0, verb.length - 1) + 'ing';
    } else if (_endsWithConsonantVowelConsonant(verb)) {
      return verb + verb[verb.length - 1] + 'ing';
    } else {
      return verb + 'ing';
    }
  }
  
  /// Generate the present perfect form of a verb
  String generatePresentPerfect(String verb) {
    if (verb.isEmpty) return '';
    
    // Handle common irregular verbs
    const Map<String, String> irregularPastParticiples = {
      'go': 'gone', 
      'have': 'had', 
      'be': 'been', 
      'do': 'done',
      'say': 'said', 
      'make': 'made', 
      'get': 'got', 
      'know': 'known',
      'take': 'taken', 
      'see': 'seen', 
      'come': 'come', 
      'think': 'thought',
      'give': 'given', 
      'find': 'found', 
      'tell': 'told', 
      'leave': 'left',
    };
    
    String pastParticiple;
    if (irregularPastParticiples.containsKey(verb.toLowerCase())) {
      pastParticiple = irregularPastParticiples[verb.toLowerCase()]!;
    } else {
      // Use the same rules as past tense for regular verbs
      pastParticiple = generatePastTense(verb);
    }
    
    return 'have $pastParticiple';
  }
  
  /// Check if a character is a vowel
  bool _isVowel(String char) {
    return 'aeiou'.contains(char.toLowerCase());
  }
  
  /// Check if a word ends with a consonant-vowel-consonant pattern
  bool _endsWithConsonantVowelConsonant(String word) {
    if (word.length < 3) return false;
    
    final lastChar = word[word.length - 1];
    final secondLastChar = word[word.length - 2];
    final thirdLastChar = word[word.length - 3];
    
    return !_isVowel(lastChar) && _isVowel(secondLastChar) && !_isVowel(thirdLastChar);
  }
} 