/// Utility class for handling text operations
class TextUtils {
  /// Truncates text to a specified length and adds an ellipsis if necessary
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  /// Capitalizes the first letter of a string
  static String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Splits text into words while respecting punctuation
  static List<String> splitIntoWords(String text) {
    final RegExp pattern = RegExp(r'\b\w+\b|[^\w\s]');
    final matches = pattern.allMatches(text);
    return matches.map((match) => match.group(0) ?? '').toList();
  }

  /// Extracts sentences from a paragraph
  static List<String> extractSentences(String paragraph) {
    final RegExp sentenceRegex = RegExp(r'[^.!?]+[.!?]+');
    final matches = sentenceRegex.allMatches(paragraph);
    return matches.map((match) => match.group(0)?.trim() ?? '').toList();
  }

  /// Removes extra whitespace from text
  static String normalizeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
} 