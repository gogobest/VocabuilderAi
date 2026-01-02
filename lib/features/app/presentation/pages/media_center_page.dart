import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/features/subtitle_extractor/presentation/pages/select_subtitle_page.dart';
import 'package:visual_vocabularies/features/media_vocabulary/presentation/pages/media_discovery_page.dart';
import 'package:visual_vocabularies/features/book_extractor/presentation/pages/select_book_page.dart';

class MediaCenterPage extends StatefulWidget {
  const MediaCenterPage({Key? key}) : super(key: key);

  @override
  State<MediaCenterPage> createState() => _MediaCenterPageState();
}

class _MediaCenterPageState extends State<MediaCenterPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);  // Update to 3 tabs
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Media Center"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Subtitle Learning"),
            Tab(text: "Book Learning"),
            Tab(text: "Media Vocabulary"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SelectSubtitlePage(isEmbedded: true),
          SelectBookPage(isEmbedded: true),
          MediaDiscoveryPage(),
        ],
      ),
    );
  }
} 