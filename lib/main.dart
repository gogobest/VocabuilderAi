import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';
import 'package:visual_vocabularies/core/theme/app_icon.dart';
import 'package:visual_vocabularies/core/theme/app_theme.dart';
import 'package:visual_vocabularies/core/theme/theme_provider.dart';
import 'package:visual_vocabularies/core/utils/dependency_injection.dart';
import 'package:visual_vocabularies/core/utils/router.dart';
import 'package:hive/hive.dart';

import 'package:visual_vocabularies/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:visual_vocabularies/features/media/data/models/ai_answer_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure Google Fonts
  if (kIsWeb) {
    // For web, we'll use bundled fonts so disable runtime fetching
    GoogleFonts.config.allowRuntimeFetching = false;
  } else {
    // For mobile, allow runtime fetching (default behavior)
    GoogleFonts.config.allowRuntimeFetching = true;
  }
  
  // Initialize dependencies
  await initDependencies();
  
  // Setup app icon
  await AppIcon.setupAppIcon();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Register Hive adapters
  Hive.registerAdapter(AIAnswerModelAdapter());
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => sl<ThemeProvider>(),
      child: const VisualVocabulariesApp(),
    ),
  );
}

/// Main application widget for Visual Vocabularies
class VisualVocabulariesApp extends StatelessWidget {
  /// Constructor for VisualVocabulariesApp
  const VisualVocabulariesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MultiBlocProvider(
      providers: [
        // Use factory from service locator to create BLoCs
        BlocProvider(create: (_) => sl<VocabularyBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Visual Vocabularies',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,
        routerConfig: AppRouter.getRouter(),
      ),
    );
  }
} 