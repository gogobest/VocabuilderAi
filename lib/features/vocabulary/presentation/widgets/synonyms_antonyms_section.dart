import 'package:flutter/material.dart';

/// Widget for displaying and editing synonyms and antonyms
class SynonymsAntonymsSection extends StatelessWidget {
  /// Whether to show the section expanded
  final bool showSection;
  
  /// Controller for synonyms field
  final TextEditingController synonymsController;
  
  /// Controller for antonyms field
  final TextEditingController antonymsController;
  
  /// Callback when section is toggled
  final VoidCallback onToggleSection;

  /// Constructor for SynonymsAntonymsSection
  const SynonymsAntonymsSection({
    super.key,
    required this.showSection,
    required this.synonymsController,
    required this.antonymsController,
    required this.onToggleSection,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList(
      elevation: 1,
      expandedHeaderPadding: EdgeInsets.zero,
      expansionCallback: (panelIndex, isExpanded) {
        onToggleSection();
      },
      children: [
        ExpansionPanel(
          headerBuilder: (context, isExpanded) {
            return const ListTile(
              title: Text('Synonyms & Antonyms'),
            );
          },
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextFormField(
                  controller: synonymsController,
                  decoration: const InputDecoration(
                    labelText: 'Synonyms',
                    hintText: 'Enter synonyms separated by commas',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: antonymsController,
                  decoration: const InputDecoration(
                    labelText: 'Antonyms',
                    hintText: 'Enter antonyms separated by commas',
                  ),
                ),
              ],
            ),
          ),
          isExpanded: showSection,
        ),
      ],
    );
  }
} 