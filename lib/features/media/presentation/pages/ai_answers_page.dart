import 'package:flutter/material.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/features/media/data/services/ai_answer_service.dart';
import 'package:visual_vocabularies/features/media/domain/entities/ai_answer.dart';
import 'package:intl/intl.dart';

class AIAnswersPage extends StatefulWidget {
  const AIAnswersPage({super.key});

  @override
  State<AIAnswersPage> createState() => _AIAnswersPageState();
}

class _AIAnswersPageState extends State<AIAnswersPage> {
  final AIAnswerService _aiAnswerService = sl<AIAnswerService>();
  List<AIAnswer> _answers = [];
  List<AIAnswer> _filteredAnswers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedMediaTitle;
  List<String> _mediaTitles = [];

  @override
  void initState() {
    super.initState();
    _loadAnswers();
  }

  Future<void> _loadAnswers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final answers = await _aiAnswerService.getAllAIAnswers();
      
      // Sort by newest first
      answers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Extract unique media titles
      final titles = <String>{};
      for (final answer in answers) {
        titles.add(answer.sourceMediaTitle);
      }
      
      setState(() {
        _answers = answers;
        _filteredAnswers = answers;
        _mediaTitles = titles.toList()..sort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load AI answers: $e')),
      );
    }
  }

  void _filterAnswers() {
    if (_searchQuery.isEmpty && _selectedMediaTitle == null) {
      setState(() {
        _filteredAnswers = _answers;
      });
      return;
    }

    final query = _searchQuery.toLowerCase();
    setState(() {
      _filteredAnswers = _answers.where((answer) {
        bool matchesQuery = query.isEmpty || 
            answer.question.toLowerCase().contains(query) || 
            answer.answer.toLowerCase().contains(query);
            
        bool matchesMedia = _selectedMediaTitle == null || 
            answer.sourceMediaTitle == _selectedMediaTitle;
            
        return matchesQuery && matchesMedia;
      }).toList();
    });
  }

  Future<void> _deleteAnswer(AIAnswer answer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Answer'),
        content: const Text('Are you sure you want to delete this answer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _aiAnswerService.deleteAIAnswer(answer.id);
      if (success) {
        setState(() {
          _answers.removeWhere((a) => a.id == answer.id);
          _filterAnswers();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Answer deleted')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete answer')),
          );
        }
      }
    }
  }

  void _viewAnswer(AIAnswer answer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(answer.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Expanded(child: Text('AI Answer')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtitle line with context
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Source Line:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(answer.subtitleLine),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Question:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(answer.question),
              const SizedBox(height: 16),
              const Text('Answer:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(answer.answer),
              const SizedBox(height: 16),
              Text(
                'From: ${answer.sourceMediaTitle}' + 
                (answer.sourceMediaSeason != null ? ' S${answer.sourceMediaSeason}' : '') +
                (answer.sourceMediaEpisode != null ? ' E${answer.sourceMediaEpisode}' : ''),
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
              Text(
                'Saved on: ${DateFormat('MMM d, yyyy').format(answer.createdAt)}',
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved AI Answers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnswers,
            tooltip: 'Refresh answers',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and filter bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search questions or answers',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterAnswers();
                        },
                      ),
                      const SizedBox(height: 8),
                      if (_mediaTitles.isNotEmpty)
                        DropdownButtonFormField<String?>(
                          value: _selectedMediaTitle,
                          decoration: const InputDecoration(
                            labelText: 'Filter by source',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All sources'),
                            ),
                            ..._mediaTitles.map(
                              (title) => DropdownMenuItem<String?>(
                                value: title,
                                child: Text(title),
                              )
                            ).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedMediaTitle = value;
                            });
                            _filterAnswers();
                          },
                        ),
                    ],
                  ),
                ),
                
                // Stats summary
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'Showing ${_filteredAnswers.length} of ${_answers.length} answers',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Answer list
                Expanded(
                  child: _filteredAnswers.isEmpty
                      ? const Center(
                          child: Text('No saved AI answers found'),
                        )
                      : ListView.builder(
                          itemCount: _filteredAnswers.length,
                          itemBuilder: (context, index) {
                            final answer = _filteredAnswers[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(answer.emoji),
                                  backgroundColor: Colors.transparent,
                                ),
                                title: Text(
                                  answer.question,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      answer.answer,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'From: ${answer.sourceMediaTitle}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _deleteAnswer(answer),
                                ),
                                onTap: () => _viewAnswer(answer),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 