import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IOSWebViewScreen extends StatefulWidget {
  const IOSWebViewScreen({super.key});

  @override
  State<IOSWebViewScreen> createState() => _IOSWebViewScreenState();
}

class _IOSWebViewScreenState extends State<IOSWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://www.socalgas.com/')); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SurveyHero (iOS)')),
      body: WebViewWidget(controller: _controller),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            // Camera extraction trigger goes here
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
