import 'package:flutter/material.dart';
import 'package:visual_vocabularies/features/vocabulary/data/services/vocabulary_ai_service.dart';

/// Widget for displaying and editing verb tense variations
class TenseVariationsSection extends StatefulWidget {
  /// Whether to show the section expanded
  final bool showSection;
  
  /// Current tense variations map
  final Map<String, String> variations;
  
  /// Word for which to generate tense variations
  final String word;
  
  /// Whether variations are currently loading
  final bool isLoading;
  
  /// Callback when section is toggled
  final VoidCallback onToggleSection;
  
  /// Callback when variations are updated
  final Function(Map<String, String>) onVariationsUpdated;

  /// Constructor for TenseVariationsSection
  const TenseVariationsSection({
    super.key,
    required this.showSection,
    required this.variations,
    required this.word,
    required this.isLoading,
    required this.onToggleSection,
    required this.onVariationsUpdated,
  });

  @override
  State<TenseVariationsSection> createState() => _TenseVariationsSectionState();
}

class _TenseVariationsSectionState extends State<TenseVariationsSection> {
  final VocabularyAiService _aiService = VocabularyAiService();
  bool _isLoading = false;
  Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(TenseVariationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.variations != widget.variations) {
      _initializeControllers();
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    // Create a new map for controllers
    final newControllers = <String, TextEditingController>{};
    
    // Standard tense list to ensure consistent order
    final tenseOrder = [
      'Present Simple',
      'Past Simple',
      'Present Continuous',
      'Present Perfect',
      'Past Continuous',
      'Past Perfect',
      'Future Simple',
      'Future Continuous',
      'Future Perfect',
    ];
    
    // Initialize controllers with values from variations
    for (final tense in tenseOrder) {
      // If we have an existing controller, update its value and reuse it
      if (_controllers.containsKey(tense)) {
        _controllers[tense]!.text = widget.variations[tense] ?? '';
        newControllers[tense] = _controllers[tense]!;
      } else {
        // Otherwise create a new controller
        newControllers[tense] = TextEditingController(
          text: widget.variations[tense] ?? '',
        );
      }
    }
    
    // Dispose any controllers that are no longer needed
    for (final tense in _controllers.keys) {
      if (!newControllers.containsKey(tense)) {
        _controllers[tense]!.dispose();
      }
    }
    
    _controllers = newControllers;
  }

  /// Generate tense variations for the current word
  Future<void> _generateTenseVariations() async {
    if (widget.word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a word first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final result = await _aiService.generateTenseVariations(widget.word);
      
      // Update the controllers with new values
      for (final entry in result.entries) {
        if (_controllers.containsKey(entry.key)) {
          _controllers[entry.key]!.text = entry.value;
        }
      }
      
      // Create updated variations map to pass to callback
      final updatedVariations = <String, String>{};
      for (final entry in _controllers.entries) {
        updatedVariations[entry.key] = entry.value.text;
      }
      
      widget.onVariationsUpdated(updatedVariations);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Update variations with current controller values
  void _updateVariations() {
    final updatedVariations = <String, String>{};
    for (final entry in _controllers.entries) {
      updatedVariations[entry.key] = entry.value.text;
    }
    widget.onVariationsUpdated(updatedVariations);
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
      elevation: 1,
      expandedHeaderPadding: EdgeInsets.zero,
      expansionCallback: (panelIndex, isExpanded) {
        widget.onToggleSection();
      },
      children: [
        ExpansionPanel(
          headerBuilder: (context, isExpanded) {
            return const ListTile(
              title: Text('Verb Tense Variations'),
            );
          },
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Generate button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: const Text('Generate Tenses'),
                    onPressed: _isLoading ? null : _generateTenseVariations,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tense form fields
                ..._controllers.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: entry.key,
                        hintText: 'Enter the ${entry.key} form',
                      ),
                      onChanged: (_) => _updateVariations(),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          isExpanded: widget.showSection,
        ),
      ],
    );
  }
} 