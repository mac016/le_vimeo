import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Only import for web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui' as ui;

void main() {
  // Register the iframe factory **before** runApp
  if (kIsWeb) {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'vimeo-iframe',
      (int viewId) => html.IFrameElement()
        ..src = 'https://player.vimeo.com/video/1020504697?h=8cb5d7236f&title=0&byline=0&portrait=0'
        ..style.border = 'none'
        ..allowFullscreen = true
        ..width = '640'
        ..height = '360'
        ..allow = 'autoplay; fullscreen; picture-in-picture',
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: VimeoPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VimeoPage extends StatefulWidget {
  const VimeoPage({super.key});

  @override
  State<VimeoPage> createState() => _VimeoPageState();
}

class _VimeoPageState extends State<VimeoPage> {
  bool _showVideo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F0F7),
      appBar: AppBar(title: const Text("Vimeo Video")),
      body: Center(
        child: _showVideo
            ? SizedBox(
                width: MediaQuery.of(context).size.width * 0.4,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: HtmlElementView(viewType: 'vimeo-iframe'),
                ),
              )
            : ElevatedButton(
                onPressed: () => setState(() => _showVideo = true),
                child: const Text('Play Video'),
              ),
      ),
    );
  }
}
