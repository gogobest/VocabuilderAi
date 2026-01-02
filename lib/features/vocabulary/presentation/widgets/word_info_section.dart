import 'package:flutter/material.dart';

/// Widget for displaying and editing basic word information
class WordInfoSection extends StatelessWidget {
  /// Controller for the word field
  final TextEditingController wordController;
  
  /// Controller for the meaning field
  final TextEditingController meaningController;
  
  /// Controller for the example field
  final TextEditingController exampleController;
  
  /// Controller for the pronunciation field
  final TextEditingController pronunciationController;
  
  /// Controller for the emoji field
  final TextEditingController emojiController;
  
  /// Currently selected category
  final String selectedCategory;
  
  /// Currently selected part of speech
  final String selectedPartOfSpeech;
  
  /// Difficulty level (1-5)
  final int difficultyLevel;
  
  /// Available categories
  final List<String> categories;
  
  /// Available parts of speech
  final List<String> partsOfSpeech;
  
  /// Callback when category changes
  final Function(String) onCategoryChanged;
  
  /// Callback when part of speech changes
  final Function(String) onPartOfSpeechChanged;
  
  /// Callback when difficulty changes
  final Function(int) onDifficultyChanged;

  /// Constructor for WordInfoSection
  const WordInfoSection({
    super.key,
    required this.wordController,
    required this.meaningController,
    required this.exampleController,
    required this.pronunciationController,
    required this.emojiController,
    required this.selectedCategory,
    required this.selectedPartOfSpeech,
    required this.difficultyLevel,
    required this.categories,
    required this.partsOfSpeech,
    required this.onCategoryChanged,
    required this.onPartOfSpeechChanged,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Text(
          'Word Information',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Word field
        TextFormField(
          controller: wordController,
          decoration: const InputDecoration(
            labelText: 'Word *',
            hintText: 'Enter the vocabulary word',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a word';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        // Meaning field
        TextFormField(
          controller: meaningController,
          decoration: const InputDecoration(
            labelText: 'Meaning *',
            hintText: 'Enter the meaning of the word',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a meaning';
            }
            return null;
          },
          maxLines: 2,
        ),
        
        const SizedBox(height: 16),
        
        // Example field
        TextFormField(
          controller: exampleController,
          decoration: const InputDecoration(
            labelText: 'Example',
            hintText: 'Enter an example sentence using this word',
          ),
          maxLines: 2,
        ),
        
        const SizedBox(height: 16),
        
        // Category dropdown
        DropdownButtonFormField<String>(
          value: selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category *',
          ),
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onCategoryChanged(value);
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Part of speech dropdown
        DropdownButtonFormField<String>(
          value: selectedPartOfSpeech,
          decoration: const InputDecoration(
            labelText: 'Part of Speech',
          ),
          items: partsOfSpeech.map((pos) {
            return DropdownMenuItem<String>(
              value: pos,
              child: Text(pos),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onPartOfSpeechChanged(value);
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Difficulty slider
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Difficulty Level'),
          subtitle: Slider(
            value: difficultyLevel.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: difficultyLevel.toString(),
            onChanged: (value) {
              onDifficultyChanged(value.round());
            },
          ),
          trailing: Text(
            difficultyLevel.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Pronunciation field
        TextFormField(
          controller: pronunciationController,
          decoration: const InputDecoration(
            labelText: 'Pronunciation',
            hintText: 'How to pronounce this word (e.g., /ˈwɜːrd/)',
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Emoji field
        TextFormField(
          controller: emojiController,
          decoration: const InputDecoration(
            labelText: 'Emoji',
            hintText: 'An emoji that represents this word',
          ),
        ),
      ],
    );
  }
} 