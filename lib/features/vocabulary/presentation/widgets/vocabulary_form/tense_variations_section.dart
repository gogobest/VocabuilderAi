import 'package:flutter/material.dart';
import 'package:visual_vocabularies/features/vocabulary/data/services/vocabulary_ai_service.dart';
import 'verb_utils.dart';

/// A widget that displays and manages verb tense variations
class TenseVariationsSection extends StatefulWidget {
  /// Controller for accessing the word value
  final TextEditingController wordController;
  
  /// Loading state
  final bool isLoading;
  
  /// AI service for generating tense variations
  final VocabularyAiService aiService;
  
  /// Initial tense variations if any
  final Map<String, String> initialTenseVariations;
  
  /// Callback when tense variations change
  final Function(Map<String, String>) onTenseVariationsChanged;

  /// Constructor for TenseVariationsSection
  const TenseVariationsSection({
    super.key,
    required this.wordController,
    required this.isLoading,
    required this.aiService,
    required this.initialTenseVariations,
    required this.onTenseVariationsChanged,
  });

  @override
  State<TenseVariationsSection> createState() => _TenseVariationsSectionState();
}

class _TenseVariationsSectionState extends State<TenseVariationsSection> {
  bool _isTenseSectionExpanded = true;
  Map<String, String> _tenseVariations = {};
  bool _loadingTenseVariations = false;
  final VerbUtils _verbUtils = VerbUtils();

  @override
  void initState() {
    super.initState();
    
    // Initialize with provided variations or generate from base verb
    if (widget.initialTenseVariations.isNotEmpty) {
      _tenseVariations = Map<String, String>.from(widget.initialTenseVariations);
    } else {
      _generateInitialTenseVariations();
    }
  }

  @override
  void didUpdateWidget(TenseVariationsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the word changes, regenerate tense variations
    if (widget.wordController.text != oldWidget.wordController.text) {
      _generateInitialTenseVariations();
    }
  }

  /// Generate initial tense variations based on the current word
  void _generateInitialTenseVariations() {
    final baseVerb = widget.wordController.text.trim();
    if (baseVerb.isEmpty) return;
    
    setState(() {
      _tenseVariations = {
        'Present Simple': baseVerb,
        'Past Simple': _verbUtils.generatePastTense(baseVerb),
        'Present Continuous': _verbUtils.generatePresentContinuous(baseVerb),
        'Present Perfect': _verbUtils.generatePresentPerfect(baseVerb),
        'Future Simple': 'will $baseVerb',
      };
    });
    
    // Notify parent of changes
    widget.onTenseVariationsChanged(_tenseVariations);
  }

  /// Generate tense variations using AI service
  Future<void> _generateTenseVariations() async {
    final verb = widget.wordController.text.trim();
    if (verb.isEmpty) return;
    
    setState(() {
      _loadingTenseVariations = true;
    });
    
    try {
      final variations = await widget.aiService.generateTenseVariations(verb);
      setState(() {
        _tenseVariations = variations;
        _loadingTenseVariations = false;
      });
      
      // Notify parent of changes
      widget.onTenseVariationsChanged(_tenseVariations);
    } catch (e) {
      // If AI service fails, use rule-based approach
      setState(() {
        _tenseVariations = {
          'Present Simple': verb,
          'Past Simple': _verbUtils.generatePastTense(verb),
          'Present Continuous': _verbUtils.generatePresentContinuous(verb),
          'Present Perfect': _verbUtils.generatePresentPerfect(verb),
          'Future Simple': 'will $verb',
        };
        _loadingTenseVariations = false;
      });
      
      // Notify parent of changes
      widget.onTenseVariationsChanged(_tenseVariations);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Using built-in tense generation (AI service unavailable)'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseVerb = widget.wordController.text.trim();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Verb Tenses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isTenseSectionExpanded 
                          ? Icons.keyboard_arrow_up 
                          : Icons.keyboard_arrow_down),
                      onPressed: () {
                        setState(() {
                          _isTenseSectionExpanded = !_isTenseSectionExpanded;
                        });
                      },
                      tooltip: _isTenseSectionExpanded 
                          ? 'Collapse tense variations' 
                          : 'Expand tense variations',
                    ),
                  ],
                ),
                if (baseVerb.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Generate'),
                    onPressed: widget.isLoading || _loadingTenseVariations 
                      ? null 
                      : _generateTenseVariations,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            
            // Loading indicator
            if (_loadingTenseVariations)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            // Conditional expandable content
            else if (_isTenseSectionExpanded) ...[
              // Display tense variations
              ..._tenseVariations.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: entry.value,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          hintText: 'Form of "${baseVerb}"',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _tenseVariations[entry.key] = value.trim();
                            // Notify parent of changes
                            widget.onTenseVariationsChanged(_tenseVariations);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ] else 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Tap to expand and view ${_tenseVariations.length} verb tense forms',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 