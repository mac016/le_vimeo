import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  WebViewPlatform.instance = WebWebViewPlatform();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Vimeo Player Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: const VimeoVideoPlayerPage(
        videoId: '1020504697',
      ),
    );
  }
}

class VimeoVideoPlayerPage extends StatefulWidget {
  final String videoId;

  const VimeoVideoPlayerPage({
    Key? key,
    required this.videoId,
  }) : super(key: key);

  @override
  State<VimeoVideoPlayerPage> createState() => _VimeoVideoPlayerPageState();
}

class _VimeoVideoPlayerPageState extends State<VimeoVideoPlayerPage> {
  WebViewController? _controller;
  String? _vimeoEmbedUrl;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showVideo = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _fetchVimeoVideoData();
  }

  void _initializeWebView() {
    _controller = WebViewController();
  }

  Future<void> _fetchVimeoVideoData() async {
    const String vimeoApiBaseUrl = 'https://api.vimeo.com/videos/';
    final String videoUrl = '$vimeoApiBaseUrl${widget.videoId}';

    final String? vimeoAccessToken = dotenv.env['VIMEO_ACCESS_TOKEN'];

    if (vimeoAccessToken == null || vimeoAccessToken.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Vimeo Access Token is not configured in .env file.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(videoUrl),
        headers: {
          'Authorization': 'Bearer $vimeoAccessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String? playerEmbedUrl = data['player_embed_url'];

        if (playerEmbedUrl != null && mounted) {
          String finalEmbedUrl = playerEmbedUrl;
          finalEmbedUrl += '&dnt=1&badge=0&byline=0&portrait=0&title=0&pip=0';

          setState(() {
            _vimeoEmbedUrl = finalEmbedUrl;
            _isLoading = false;
            _controller?.loadRequest(Uri.parse(_vimeoEmbedUrl!));
          });
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'Could not find player embed URL in Vimeo response.';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load video data from Vimeo API. Status: ${response.statusCode}';
            _isLoading = false;
          });
        }
        print('Failed to load Vimeo video data: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred while fetching video data: $e';
          _isLoading = false;
        });
      }
      print('Error fetching Vimeo video data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vimeo POC (Web Only)',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          // This block now correctly uses 'child:' for the Center widget
          if (!_showVideo)
            Center( // Correctly wraps its content with 'child:'
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.blueAccent)
                  : _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            if (_vimeoEmbedUrl != null) {
                              setState(() {
                                _showVideo = true;
                              });
                            } else {
                              setState(() {
                                _errorMessage = 'Video data not yet loaded. Please try again.';
                              });
                            }
                          },
                          child: const Text('Play Vimeo Video'),
                        ),
            )
          else if (_showVideo && _vimeoEmbedUrl != null && _controller != null)
            Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                width: MediaQuery.of(context).size.width,
                child: WebViewWidget(controller: _controller!),
              ),
            ),
          // These loading/error indicators are now part of the conditional rendering.
          // They will only show if _showVideo is true, but video is still loading or has an error.
          if (_showVideo && _isLoading && _vimeoEmbedUrl == null)
            const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            ),
          if (_showVideo && _errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}