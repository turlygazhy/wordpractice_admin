import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Conditional import for web audio
import 'audio_player_web_stub.dart'
    if (dart.library.html) 'audio_player_web.dart' as web_audio;

// Conditional import for web HTML elements
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// Screen for displaying course details
/// Accepts courseId to fetch and display course information
class CourseDetailScreen extends StatelessWidget {
  final String courseId;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали курса'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Курс не найден'));
          }

          final course = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(course),
                const SizedBox(height: 16),
                _buildDescription(course),
                const SizedBox(height: 16),
                _buildDisplayedStatus(course),
                const SizedBox(height: 24),
                _buildWordsList(course),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds title section
  Widget _buildTitle(Map<String, dynamic> course) {
    return Text(
      course['title'] ?? 'Без названия',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Builds description section
  Widget _buildDescription(Map<String, dynamic> course) {
    return Text(
      course['description'] ?? '',
      style: const TextStyle(fontSize: 16),
    );
  }

  /// Builds displayed status section
  Widget _buildDisplayedStatus(Map<String, dynamic> course) {
    final displayed = course['displayed'] ?? false;
    return Row(
      children: [
        const Text(
          'Отображается: ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Chip(
          label: Text(displayed ? 'Да' : 'Нет'),
          backgroundColor: displayed ? Colors.green.shade100 : Colors.red.shade100,
        ),
      ],
    );
  }

  /// Builds words list section
  Widget _buildWordsList(Map<String, dynamic> course) {
    final words = course['words'] as List<dynamic>? ?? [];

    if (words.isEmpty) {
      return const Text(
        'Слов нет',
        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Слова (${words.length}):',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: words.length,
          itemBuilder: (context, index) {
            final word = words[index] as Map<String, dynamic>;
            return _buildWordCard(word, index);
          },
        ),
      ],
    );
  }

  /// Builds word card with all word information
  Widget _buildWordCard(Map<String, dynamic> word, int index) {
    return WordCard(
      word: word,
      index: index,
    );
  }
}

/// Widget for displaying a single word card with image and audio
class WordCard extends StatefulWidget {
  final Map<String, dynamic> word;
  final int index;

  const WordCard({
    super.key,
    required this.word,
    required this.index,
  });

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  AudioPlayer? _audioPlayer;
  web_audio.WebAudioPlayer? _webAudioPlayer;
  bool _isPlaying = false;
  String? _currentAudioUrl;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _webAudioPlayer = web_audio.WebAudioPlayer();
      _webAudioPlayer!.onEnded.listen((_) {
        if (mounted) {
          setState(() => _isPlaying = false);
        }
      });
    } else {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() => _isPlaying = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    _webAudioPlayer?.dispose();
    super.dispose();
  }

  /// Plays audio from URL
  Future<void> _playAudio(String audioUrl) async {
    if (audioUrl.isEmpty) return;

    if (kIsWeb) {
      await _playAudioWeb(audioUrl);
      return;
    }

    try {
      if (_isPlaying && _currentAudioUrl == audioUrl) {
        await _audioPlayer!.stop();
        setState(() {
          _isPlaying = false;
          _currentAudioUrl = null;
        });
      } else {
        await _audioPlayer!.play(UrlSource(audioUrl));
        setState(() {
          _isPlaying = true;
          _currentAudioUrl = audioUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка воспроизведения: $e')),
        );
        setState(() {
          _isPlaying = false;
          _currentAudioUrl = null;
        });
      }
    }
  }

  /// Plays audio on web platform using HTML5 Audio
  Future<void> _playAudioWeb(String audioUrl) async {
    if (!kIsWeb || _webAudioPlayer == null) return;

    try {
      if (_isPlaying && _currentAudioUrl == audioUrl) {
        _webAudioPlayer!.pause();
        setState(() {
          _isPlaying = false;
          _currentAudioUrl = null;
        });
      } else {
        await _webAudioPlayer!.play(audioUrl);
        setState(() {
          _isPlaying = true;
          _currentAudioUrl = audioUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка воспроизведения: $e')),
        );
        setState(() {
          _isPlaying = false;
          _currentAudioUrl = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final arabic = widget.word['arabic'] ?? '';
    final translation = widget.word['translation'] ?? '';
    final audioUrl = widget.word['audioUrl'] ?? '';
    final imageUrl = widget.word['imageUrl'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWordHeader(),
            const SizedBox(height: 12),
            _buildContent(arabic, translation, audioUrl, imageUrl),
          ],
        ),
      ),
    );
  }

  /// Builds word header with index
  Widget _buildWordHeader() {
    return Text(
      'Слово ${widget.index + 1}',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Builds main content with image, text and audio
  Widget _buildContent(
    String arabic,
    String translation,
    String audioUrl,
    String imageUrl,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImage(imageUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildArabicText(arabic),
              const SizedBox(height: 8),
              _buildTranslationText(translation),
              const SizedBox(height: 8),
              _buildAudioButton(audioUrl),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds image widget
  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    // Clean and validate URL
    final cleanUrl = imageUrl.trim();
    if (cleanUrl.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    // For web platform, try using HTML img element directly
    if (kIsWeb) {
      return _buildWebImage(cleanUrl);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: cleanUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        httpHeaders: const {
          'Accept': 'image/*',
        },
        memCacheWidth: 100,
        memCacheHeight: 100,
        maxWidthDiskCache: 200,
        maxHeightDiskCache: 200,
        imageBuilder: (context, imageProvider) {
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
        placeholder: (context, url) => Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) {
          // Log error for debugging
          debugPrint('Image load error for URL: $cleanUrl');
          debugPrint('Error type: ${error.runtimeType}');
          debugPrint('Error: $error');
          
          // Try fallback with Image.network
          return _buildFallbackImage(cleanUrl);
        },
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
      ),
    );
  }

  /// Builds image widget for web platform using HTML img element
  Widget _buildWebImage(String imageUrl) {
    if (!kIsWeb) {
      return _buildFallbackImage(imageUrl);
    }

    // Use HTML img element directly for web to avoid CORS issues
    try {
      return _buildHtmlImage(imageUrl);
    } catch (e) {
      debugPrint('Error creating HTML image: $e');
      return _buildFallbackImage(imageUrl);
    }
  }

  /// Builds image using HTML img element via platform view
  Widget _buildHtmlImage(String imageUrl) {
    if (!kIsWeb) {
      return _buildFallbackImage(imageUrl);
    }

    // Create a unique view ID
    final viewId = 'image_${widget.index}_${imageUrl.hashCode}';
    
    // Register platform view
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) {
        final img = html.ImageElement()
          ..src = imageUrl
          ..style.width = '100px'
          ..style.height = '100px'
          ..style.objectFit = 'cover'
          ..style.borderRadius = '8px'
          ..onError.listen((_) {
            debugPrint('HTML image load error for: $imageUrl');
          });
        return img;
      },
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 100,
        height: 100,
        child: HtmlElementView(viewType: viewId),
      ),
    );
  }

  /// Builds fallback image widget using Image.network with different approach
  Widget _buildFallbackImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Fallback image also failed: $error');
          debugPrint('Stack trace: $stackTrace');
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, color: Colors.grey, size: 32),
                const SizedBox(height: 4),
                Text(
                  'Ошибка\nзагрузки',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  /// Builds Arabic text
  Widget _buildArabicText(String arabic) {
    return Text(
      arabic.isEmpty ? '(пусто)' : arabic,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Builds translation text
  Widget _buildTranslationText(String translation) {
    return Text(
      translation.isEmpty ? '(пусто)' : translation,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.grey,
      ),
    );
  }

  /// Builds audio play button
  Widget _buildAudioButton(String audioUrl) {
    if (audioUrl.isEmpty) {
      return const Row(
        children: [
          Icon(Icons.volume_off, color: Colors.grey, size: 20),
          SizedBox(width: 4),
          Text(
            'Аудио недоступно',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }

    if (kIsWeb) {
      return InkWell(
        onTap: () => _playAudio(audioUrl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: Colors.blue,
              size: 32,
            ),
            const SizedBox(width: 4),
            Text(
              _isPlaying ? 'Воспроизведение...' : 'Воспроизвести',
              style: const TextStyle(fontSize: 14, color: Colors.blue),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _playAudio(audioUrl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isPlaying ? Icons.pause_circle : Icons.play_circle,
            color: Colors.blue,
            size: 32,
          ),
          const SizedBox(width: 4),
          Text(
            _isPlaying ? 'Воспроизведение...' : 'Воспроизвести',
            style: const TextStyle(fontSize: 14, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}

