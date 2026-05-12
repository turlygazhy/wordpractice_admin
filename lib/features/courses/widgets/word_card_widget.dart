import 'dart:developer' show log;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:wordpractice_admin/features/courses/state/course_models.dart';

import 'package:wordpractice_admin/audio_player_web_stub.dart'
    if (dart.library.html) 'package:wordpractice_admin/audio_player_web.dart'
    as web_audio;

import 'package:wordpractice_admin/features/courses/widgets/word_card_network_image_stub.dart'
    if (dart.library.html) 'package:wordpractice_admin/features/courses/widgets/word_card_network_image_web.dart'
    as word_card_network_image;

/// Widget for displaying a single word card with media and actions.
/// Accepts word model, index and callbacks for edit and delete.
class WordCardWidget extends StatefulWidget {
  final CourseWord word;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WordCardWidget({
    super.key,
    required this.word,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<WordCardWidget> createState() => _WordCardWidgetState();
}

class _WordCardWidgetState extends State<WordCardWidget> {
  AudioPlayer? _audioPlayer;
  web_audio.WebAudioPlayer? _webAudioPlayer;
  bool _isPlaying = false;
  String? _currentAudioUrl;

  @override
  void initState() {
    super.initState();
    final w = widget.word;
    final hasImg = w.imageUrl.trim().isNotEmpty;
    final hasAud = w.audioUrl.trim().isNotEmpty;
    log(
      'WordCard init: index=${widget.index} arabicLen=${w.arabic.length} '
      'translationLen=${w.translation.length} '
      'planImage=${hasImg ? (kIsWeb ? 'HtmlElementView(<img>)' : 'CachedNetworkImage') : 'icon image_not_supported'} '
      'planAudio=${hasAud ? 'play control' : 'Аудио недоступно'}',
      name: 'CourseOpen',
    );
    if (hasImg) {
      log(
        'WordCard init: index=${widget.index} imageUrl ${_wordCardUrlPreview(w.imageUrl)}',
        name: 'CourseOpen',
      );
    }
    if (hasAud) {
      log(
        'WordCard init: index=${widget.index} audioUrl ${_wordCardUrlPreview(w.audioUrl)}',
        name: 'CourseOpen',
      );
    }
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

  /// Plays or pauses audio from URL depending on current state.
  /// Uses platform specific implementation for web and other platforms.
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

  /// Plays or pauses audio for web platform using HTML5 Audio.
  /// Uses custom web audio player implementation.
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
    return _buildCard();
  }

  /// Builds card container for word information and actions.
  /// Composes header, content and action row.
  Widget _buildCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildContent(),
            const SizedBox(height: 8),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// Builds header with word index.
  /// Shows human friendly number starting from one.
  Widget _buildHeader() {
    return Text(
      'Слово ${widget.index + 1}',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Builds main content with image, arabic text, translation and audio button.
  /// Uses flexible row layout for desktop and web screens.
  Widget _buildContent() {
    final word = widget.word;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildImage(word.imageUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildArabicText(word.arabic),
              const SizedBox(height: 8),
              _buildTranslationText(word.translation),
              const SizedBox(height: 8),
              _buildAudioButton(word.audioUrl),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds action row with edit and delete buttons.
  /// Delegates handling to callbacks passed from parent.
  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: widget.onEdit,
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Редактировать'),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: widget.onDelete,
          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
          label: const Text(
            'Удалить',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  /// Builds image widget for word.
  /// Shows placeholder when image URL is empty or invalid.
  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      log(
        'WordCard image: data empty -> placeholder image_not_supported '
        'index=${widget.index}',
        name: 'CourseOpen',
      );
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

    final cleanUrl = imageUrl.trim();
    if (cleanUrl.isEmpty) {
      log(
        'WordCard image: trim empty -> placeholder index=${widget.index}',
        name: 'CourseOpen',
      );
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

    log(
      'WordCard image: start platform image widget index=${widget.index} '
      'kIsWeb=$kIsWeb url=${_wordCardUrlPreview(cleanUrl)}',
      name: 'CourseOpen',
    );

    return word_card_network_image.buildWordCardNetworkImage(
      cleanUrl: cleanUrl,
      cardIndex: widget.index,
    );
  }

  /// Builds arabic text widget.
  /// Shows placeholder when text is empty.
  Widget _buildArabicText(String arabic) {
    return Text(
      arabic.isEmpty ? '(пусто)' : arabic,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Builds translation text widget.
  /// Shows placeholder when text is empty.
  Widget _buildTranslationText(String translation) {
    return Text(
      translation.isEmpty ? '(пусто)' : translation,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.grey,
      ),
    );
  }

  /// Builds audio play button row.
  /// Shows disabled state when audio URL is empty.
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

String _wordCardUrlPreview(String url, [int max = 120]) {
  final t = url.trim();
  if (t.isEmpty) return '(empty)';
  if (t.length <= max) return t;
  return '${t.substring(0, max)}… totalLen=${t.length}';
}

