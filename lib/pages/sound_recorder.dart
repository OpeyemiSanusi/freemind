import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:flutter_sound_lite/public/flutter_sound_recorder.dart';
//import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart'; //for the audiosource.microphone to work
import 'package:permission_handler/permission_handler.dart';

//const audioSource = AudioSource.microphone;

class SoundRecorder {
  final pathToSaveAudio = 'audio_example.aac';

  FlutterSoundRecorder? _audiorecorder; //? IS NULLSAFETY - 'if not = null do'
  bool isRecorderInitialised =
      false; //check if we recorder is initialized and has recording permission
  bool get isRecording => _audiorecorder!.isRecording; //check if it recording

  //Method to initialize/Freshly start the recorder & also ask permission to use mic
  Future init() async {
    _audiorecorder = FlutterSoundRecorder();

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone Permission not granted');
    }

    await _audiorecorder!.openAudioSession(); //start the recorders activities
    isRecorderInitialised = true;
  }

  void dispose() {
    _audiorecorder!.closeAudioSession();
    _audiorecorder = null;
    isRecorderInitialised = false;
  }

  //method to start recording...made it private so we can only access it with the method 'toggleRecording'
  Future record() async {
    if (isRecorderInitialised)
      return await _audiorecorder!.startRecorder(
        toFile: pathToSaveAudio,
        //audioSource: audioSource,
        // codec: Codec.aacMP4,
      );
  }

  //method to stop recording...made it private so we can only access it with the method 'toggleRecording'
  Future stop() async {
    if (isRecorderInitialised) return await _audiorecorder!.stopRecorder();
  }

  //switch between record and stop
  toggleRecording() async {
    if (_audiorecorder!.isStopped) {
      await record();
    } else {
      await stop();
    }
  }
}
