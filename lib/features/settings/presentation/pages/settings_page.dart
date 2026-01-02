import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/theme/theme_provider.dart';
import 'package:visual_vocabularies/core/utils/ai_service.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/utils/secure_storage_service.dart';
import 'package:visual_vocabularies/core/utils/tts_config_service.dart';
import 'package:visual_vocabularies/core/utils/tracking_service.dart';
import 'package:visual_vocabularies/features/vocabulary/presentation/widgets/vocabulary_form/tts_helper.dart';
import 'package:go_router/go_router.dart';

/// Settings page for the application
class SettingsPage extends StatefulWidget {
  /// Default constructor
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SecureStorageService _secureStorage = sl<SecureStorageService>();
  final AiService _aiService = sl<AiService>();
  final TtsConfigService _ttsConfigService = sl<TtsConfigService>();
  late final TrackingService _trackingService;
  late final TtsHelper _ttsHelper;
  
  String _selectedAiProvider = 'gemini';
  bool _isLoading = false;
  String? _giphyApiKey;
  
  // TTS settings
  String? _selectedTtsEngine;
  String _selectedTtsLanguage = 'en-US';
  double _ttsRate = 0.5;
  double _ttsPitch = 1.0;
  double _ttsVolume = 1.0;
  List<String> _availableTtsEngines = [];
  List<String> _availableTtsLanguages = [];
  
  @override
  void initState() {
    super.initState();
    _ttsHelper = TtsHelper(context);
    _loadSettings();
    _loadTtsSettings();
    _trackingService = sl<TrackingService>();
    
    // Track page view
    _trackingService.trackNavigation('Settings Page');
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final provider = await _aiService.getSelectedProvider();
      final giphyKey = await _secureStorage.getGiphyApiKey();
      
      setState(() {
        _selectedAiProvider = provider;
        _giphyApiKey = giphyKey;
      });
    } catch (e) {
      // Handle error if needed
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// Load TTS settings
  Future<void> _loadTtsSettings() async {
    try {
      // Get current TTS settings
      final settings = await _ttsHelper.getCurrentSettings();
      
      setState(() {
        _selectedTtsEngine = settings['engine'];
        _selectedTtsLanguage = settings['language'];
        _ttsRate = settings['rate'];
        _ttsPitch = settings['pitch'];
        _ttsVolume = settings['volume'];
      });
      
      // Get available engines and languages
      if (mounted) {
        final engines = await _ttsHelper.getAvailableEngines();
        final languages = await _ttsHelper.getAvailableLanguages();
        
        if (mounted) {
          setState(() {
            _availableTtsEngines = engines;
            _availableTtsLanguages = languages;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading TTS settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            onPressed: () => _showResetSettingsDialog(context),
            icon: const Icon(Icons.restore),
            tooltip: 'Reset settings',
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appearance Section
                _buildSectionHeader('Appearance', Icons.palette_outlined),
                const SizedBox(height: 16),
                _buildThemeOptions(),
                
                const SizedBox(height: 24),
                
                // AI Provider Section
                _buildSectionHeader('AI Provider', null, 'Select and configure your AI provider'),
                _buildProviderOption(
                  title: 'Gemini',
                  subtitle: 'Powered by Google\'s Gemini AI',
                  icon: Icons.auto_awesome,
                  value: 'gemini',
                ),
                _buildProviderOption(
                  title: 'Claude',
                  subtitle: 'Powered by Anthropic\'s Claude AI',
                  icon: Icons.psychology,
                  value: 'claude',
                ),
                _buildProviderOption(
                  title: 'ChatGPT',
                  subtitle: 'Powered by OpenAI\'s GPT models',
                  icon: Icons.chat,
                  value: 'chatgpt',
                ),
                _buildProviderOption(
                  title: 'Qwen',
                  subtitle: 'Powered by Alibaba\'s Qwen models',
                  icon: Icons.language,
                  value: 'qwen',
                ),
                _buildProviderOption(
                  title: 'Custom API',
                  subtitle: 'Connect to your own AI API endpoint',
                  icon: Icons.settings_ethernet,
                  value: 'custom',
                ),
                
                const SizedBox(height: 24),
                
                // Text-to-Speech Settings Section
                _buildSectionHeader('Text-to-Speech', null, 'Configure text-to-speech settings'),
                
                _buildTtsSettings(),
                
                const SizedBox(height: 24),
                
                // Media Generation Section
                _buildSectionHeader('Media Generation', null, 'Configure image and animation providers'),
                
                // GIPHY API Key Card
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: const Text('GIPHY API Key'),
                    subtitle: Text(_giphyApiKey != null && _giphyApiKey!.isNotEmpty 
                      ? 'API key configured: ${_giphyApiKey!.substring(0, 4)}...${_giphyApiKey!.substring(_giphyApiKey!.length - 4)}'
                      : 'Set up GIPHY API key for animated GIFs'),
                    leading: const Icon(Icons.gif, color: Colors.amber),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _showGiphyApiKeyDialog,
                    ),
                    onTap: _showGiphyApiKeyDialog,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Data Management Section
                _buildSectionHeader('Data Management', null, 'Manage your app data'),
                
                ListTile(
                  title: const Text('Backup & Restore Data'),
                  subtitle: const Text('Export or import your vocabulary data'),
                  leading: const Icon(Icons.backup, color: Colors.blue),
                  onTap: () => context.push(AppConstants.dataBackupRoute),
                ),
                
                ListTile(
                  title: const Text('Reset All Settings'),
                  subtitle: const Text('Clear all API keys and preferences'),
                  leading: const Icon(Icons.restore, color: Colors.red),
                  onTap: () => _showResetConfirmation(),
                ),
              ],
            ),
          ),
    );
  }
  
  Widget _buildSectionHeader(String title, [IconData? icon, String? subtitle]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          const Divider(),
        ],
      ),
    );
  }
  
  void _showGiphyApiKeyDialog() {
    final TextEditingController apiKeyController = TextEditingController();
    
    // Load existing key if available
    if (_giphyApiKey != null && _giphyApiKey!.isNotEmpty) {
      apiKeyController.text = _giphyApiKey!;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set GIPHY API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your GIPHY API key',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You can get a GIPHY API key from the GIPHY Developer Portal at developers.giphy.com',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final apiKey = apiKeyController.text.trim();
              await _secureStorage.saveGiphyApiKey(apiKey);
              setState(() {
                _giphyApiKey = apiKey;
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('GIPHY API key saved')),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    ).then((_) => apiKeyController.dispose());
  }
  
  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings?'),
        content: const Text(
          'This will delete all your API keys and preferences. This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _secureStorage.deleteAllApiKeys();
              setState(() {
                _selectedAiProvider = 'gemini';
                _giphyApiKey = null;
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All settings have been reset')),
                );
              }
            },
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProviderOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedAiProvider == value;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    Color? cardColor;
    Color? textColor;
    Color? iconColor;
    if (isSelected) {
      if (isDarkMode) {
        cardColor = theme.colorScheme.primary.withOpacity(0.18);
        textColor = Colors.white;
        iconColor = theme.colorScheme.primary;
      } else {
        cardColor = Colors.blue.shade50;
        textColor = Colors.black;
        iconColor = Colors.blue;
      }
    }
    
    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: cardColor,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? textColor : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected ? textColor?.withOpacity(0.85) : null,
          ),
        ),
        leading: Icon(
          icon,
          color: isSelected ? iconColor : Colors.grey,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.key),
              tooltip: 'Set API Key',
              onPressed: () => _showApiKeyDialog(value),
              color: isSelected ? textColor : null,
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedAiProvider,
              onChanged: (newValue) async {
                if (newValue != null) {
                  await _aiService.setSelectedProvider(newValue);
                  setState(() {
                    _selectedAiProvider = newValue;
                  });
                }
              },
              activeColor: isSelected ? iconColor : null,
            ),
          ],
        ),
        onTap: () async {
          await _aiService.setSelectedProvider(value);
          setState(() {
            _selectedAiProvider = value;
          });
        },
      ),
    );
  }
  
  void _showApiKeyDialog(String provider) {
    final TextEditingController apiKeyController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    
    // Set current values if available
    _loadExistingApiKey(provider, apiKeyController, urlController);
    
    String title;
    Widget content;
    
    // Configure dialog based on provider
    switch (provider) {
      case 'gemini':
        title = 'Set Gemini API Key';
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your Gemini API key',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'You can get a Gemini API key from Google AI Studio.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        );
        break;
        
      case 'claude':
        title = 'Set Claude API Key';
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your Anthropic Claude API key',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'You can get a Claude API key from the Anthropic console.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        );
        break;
        
      case 'chatgpt':
        title = 'Set ChatGPT API Key';
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your OpenAI API key',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'You can get a ChatGPT API key from the OpenAI platform.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        );
        break;
        
      case 'qwen':
        title = 'Set Qwen API Key';
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your Qwen API key',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'You can get a Qwen API key from the Alibaba console.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        );
        break;
        
      case 'custom':
        title = 'Set Custom API Details';
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'API URL',
                hintText: 'Enter your custom API endpoint URL',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key (Optional)',
                hintText: 'Enter your API key if required',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'The custom API should accept and return JSON data in a compatible format.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        );
        break;
        
      default:
        title = 'Set API Key';
        content = TextField(
          controller: apiKeyController,
          decoration: const InputDecoration(
            labelText: 'API Key',
            hintText: 'Enter your API key',
          ),
          obscureText: true,
        );
    }
    
    // Use a bool to track if we're testing connection
    bool isTestingConnection = false;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: content,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: isTestingConnection ? null : () async {
                  final apiKey = apiKeyController.text.trim();
                  final apiUrl = urlController.text.trim();
                  
                  // Save temporarily for testing
                  await _saveApiKey(provider, apiKey, apiUrl);
                  
                  // Test the connection
                  setDialogState(() {
                    isTestingConnection = true;
                  });
                  
                  final connectionTest = await _aiService.testConnection();
                  
                  setDialogState(() {
                    isTestingConnection = false;
                  });
                  
                  if (connectionTest['success']) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Connection successful with $provider!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Connection failed: ${connectionTest['message']}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: isTestingConnection 
                  ? const SizedBox(
                      width: 16, 
                      height: 16, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : const Text('TEST CONNECTION'),
              ),
              ElevatedButton(
                onPressed: isTestingConnection ? null : () async {
                  final apiKey = apiKeyController.text.trim();
                  final apiUrl = urlController.text.trim();
                  
                  await _saveApiKey(provider, apiKey, apiUrl);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Settings saved for $provider'),
                      ),
                    );
                  }
                },
                child: const Text('SAVE'),
              ),
            ],
          );
        }
      ),
    );
  }
  
  Future<void> _loadExistingApiKey(
    String provider, 
    TextEditingController apiKeyController,
    TextEditingController urlController
  ) async {
    try {
      String apiKey = '';
      String apiUrl = '';
      
      switch (provider) {
        case 'gemini':
          apiKey = await _secureStorage.getGeminiApiKey();
          break;
        case 'claude':
          apiKey = await _secureStorage.getClaudeApiKey();
          break;
        case 'chatgpt':
          apiKey = await _secureStorage.getChatGptApiKey();
          break;
        case 'qwen':
          apiKey = await _secureStorage.getQwenApiKey();
          break;
        case 'custom':
          apiKey = await _secureStorage.getCustomApiKey();
          apiUrl = await _secureStorage.getCustomApiUrl();
          break;
      }
      
      apiKeyController.text = apiKey;
      urlController.text = apiUrl;
    } catch (e) {
      // Handle error
    }
  }
  
  Future<void> _saveApiKey(String provider, String apiKey, String apiUrl) async {
    try {
      switch (provider) {
        case 'gemini':
          await _secureStorage.saveGeminiApiKey(apiKey);
          break;
        case 'claude':
          await _secureStorage.saveClaudeApiKey(apiKey);
          break;
        case 'chatgpt':
          await _secureStorage.saveChatGptApiKey(apiKey);
          break;
        case 'qwen':
          await _secureStorage.saveQwenApiKey(apiKey);
          break;
        case 'custom':
          await _secureStorage.saveCustomApiKey(apiKey);
          await _secureStorage.saveCustomApiUrl(apiUrl);
          break;
      }
      
      // Set as selected provider
      await _aiService.setSelectedProvider(provider);
      setState(() {
        _selectedAiProvider = provider;
      });
      
    } catch (e) {
      // Handle error
    }
  }
  
  /// Builds the theme options section
  Widget _buildThemeOptions() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Light Theme'),
                    leading: const Icon(Icons.light_mode),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  ),
                ),
                Radio<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Dark Theme'),
                    leading: const Icon(Icons.dark_mode),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  ),
                ),
                Radio<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('System Theme'),
                    leading: const Icon(Icons.settings_system_daydream),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  ),
                ),
                Radio<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: themeProvider.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// Build TTS settings card
  Widget _buildTtsSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // TTS Engine selection (Android only)
          if (_availableTtsEngines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TTS Engine',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select TTS Engine',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedTtsEngine,
                    items: _availableTtsEngines.map((engine) {
                      return DropdownMenuItem<String>(
                        value: engine,
                        child: Text(engine),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTtsEngine = value;
                        });
                        _ttsHelper.setEngine(value);
                        
                        // Refresh languages for the new engine
                        _loadTtsSettings();
                      }
                    },
                  ),
                ],
              ),
            ),
          
          // TTS Language selection
          if (_availableTtsLanguages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TTS Language',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Language',
                      border: OutlineInputBorder(),
                    ),
                    value: _availableTtsLanguages.contains(_selectedTtsLanguage) 
                        ? _selectedTtsLanguage 
                        : _availableTtsLanguages.first,
                    items: _availableTtsLanguages.map((language) {
                      return DropdownMenuItem<String>(
                        value: language,
                        child: Text(language),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTtsLanguage = value;
                        });
                        _ttsHelper.setLanguage(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          
          // Speech Rate slider
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Speech Rate',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    const Text('Slow'),
                    Expanded(
                      child: Slider(
                        value: _ttsRate,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        label: _ttsRate.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _ttsRate = value;
                          });
                        },
                        onChangeEnd: (value) {
                          _ttsHelper.setRate(value);
                        },
                      ),
                    ),
                    const Text('Fast'),
                  ],
                ),
              ],
            ),
          ),
          
          // Pitch slider
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pitch',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    const Text('Low'),
                    Expanded(
                      child: Slider(
                        value: _ttsPitch,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        label: _ttsPitch.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _ttsPitch = value;
                          });
                        },
                        onChangeEnd: (value) {
                          _ttsHelper.setPitch(value);
                        },
                      ),
                    ),
                    const Text('High'),
                  ],
                ),
              ],
            ),
          ),
          
          // Volume slider
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Volume',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.volume_down),
                    Expanded(
                      child: Slider(
                        value: _ttsVolume,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        label: _ttsVolume.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _ttsVolume = value;
                          });
                        },
                        onChangeEnd: (value) {
                          _ttsHelper.setVolume(value);
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up),
                  ],
                ),
              ],
            ),
          ),
          
          // Test button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                _ttsHelper.speak('This is a test of the text-to-speech system');
              },
              icon: const Icon(Icons.volume_up),
              label: const Text('Test Speech'),
            ),
          ),
          
          // Reset to defaults button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton.icon(
              onPressed: () async {
                await _ttsConfigService.resetToDefaults();
                _loadTtsSettings();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset to Defaults'),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings?'),
        content: const Text(
          'This will delete all your API keys and preferences. This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _secureStorage.deleteAllApiKeys();
              setState(() {
                _selectedAiProvider = 'gemini';
                _giphyApiKey = null;
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All settings have been reset')),
                );
              }
            },
            child: const Text('RESET'),
          ),
        ],
      ),
    );
  }
} 