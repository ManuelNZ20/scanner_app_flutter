import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final _player = AudioPlayer();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (!_isInitialized) {
      await _player.setSource(AssetSource('sounds/scan_sound.mp3'));
      _isInitialized = true;
    }
  }

  static Future<void> playScanSound() async {
    try {
      await initialize();
      await _player.seek(Duration.zero);
      await _player.resume();
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  static void dispose() {
    _player.dispose();
  }
}
