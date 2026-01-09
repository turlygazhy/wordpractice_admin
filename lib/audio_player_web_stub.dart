// Stub file for non-web platforms
class WebAudioPlayer {
  dynamic get audioElement => null;
  
  Future<void> play(String url) async {
    // Stub
  }
  
  void pause() {
    // Stub
  }
  
  void dispose() {
    // Stub
  }
  
  Stream<void> get onEnded => const Stream.empty();
}
