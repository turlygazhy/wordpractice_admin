// Web implementation using dart:html
import 'dart:html' as html;
import 'dart:async';

class WebAudioPlayer {
  html.AudioElement? _audioElement;
  final StreamController<void> _endedController = StreamController<void>.broadcast();

  html.AudioElement? get audioElement => _audioElement;

  WebAudioPlayer() {
    _audioElement = html.AudioElement();
    _audioElement!.onEnded.listen((_) {
      _endedController.add(null);
    });
  }

  Future<void> play(String url) async {
    if (_audioElement != null) {
      _audioElement!.src = url;
      await _audioElement!.play();
    }
  }

  void pause() {
    _audioElement?.pause();
    _audioElement?.currentTime = 0;
  }

  void dispose() {
    _audioElement?.pause();
    _audioElement?.src = '';
    _endedController.close();
  }

  Stream<void> get onEnded => _endedController.stream;
}
