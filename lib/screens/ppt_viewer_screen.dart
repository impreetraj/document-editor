import 'package:flutter/material.dart';
import 'package:offline_document_viewer/offline_document_viewer.dart';

class PptViewerScreen extends StatefulWidget {
  final String filePath;

  const PptViewerScreen({super.key, required this.filePath});

  @override
  State<PptViewerScreen> createState() => _PptViewerScreenState();
}

class _PptViewerScreenState extends State<PptViewerScreen> {
  final DocumentViewController _controller = DocumentViewController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
 

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        foregroundColor: Colors.white,
        title: const Text('PPT Viewer'),
        elevation: 0,
      ),
      body: DocumentView(
        backgroundColor: const Color(0xFF1E1E1E),
        source: DocumentSource.file(widget.filePath),
        controller: _controller,
        renderTimeout: const Duration(seconds: 120),
        placeholderBuilder: (context) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Rendering slides...',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              SizedBox(height: 8),
              Text('This may take a moment on first load',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        errorBuilder: (context, failure) {
          return const Center(
            child: Text(
              'Failed to load document',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          );
        },
      ),
    );
  }
}
