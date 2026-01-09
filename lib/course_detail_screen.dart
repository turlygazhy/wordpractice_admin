import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';

// Conditional import for web audio
import 'audio_player_web_stub.dart'
    if (dart.library.html) 'audio_player_web.dart' as web_audio;

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.broken_image, color: Colors.grey),
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
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: child,
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

