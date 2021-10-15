import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:flutter_sound_lite/public/flutter_sound_player.dart';

class SoundPlayer {
  FlutterSoundPlayer? _audioplayer;
  final pathToReadAudio = 'audio_example.aac';
  bool get isStopped => _audioplayer!.isPlaying; //check if it

  init() {
    _audioplayer = FlutterSoundPlayer();
    _audioplayer!.openAudioSession();
  }

  dispose() {
    _audioplayer!.closeAudioSession();
    _audioplayer = null;
  }

  Future play(dowhenFinished) async {
    await _audioplayer!
        .startPlayer(fromURI: pathToReadAudio, whenFinished: dowhenFinished);
  }

  Future _stop() async {
    await _audioplayer!.stopPlayer();
  }

  togglePlayer(dowhenFinished) async {
    if (_audioplayer!.isStopped) {
      await play(dowhenFinished);
    } else {
      await _stop();
    }
  }

  Future playListenPage({
    String? url,
  }) async {
    await _audioplayer!.startPlayer(fromURI: url);
  }

  Future pauseListenPage() async {
    await _audioplayer!.pausePlayer();
  }

  Future resumeListenPage() async {
    await _audioplayer!.resumePlayer();
  }

  bool checkifAudioisPaused() {
    if (_audioplayer!.isPaused == true) {
      return true;
    } else
      return false;
  }
}
