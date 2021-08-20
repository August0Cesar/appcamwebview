import 'dart:async';
import 'dart:io' as io;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:path_provider/path_provider.dart';

const AUDIO_IN_RECORDING = "Audio já esta em gravação";
const NOT_PERMISSION_RECORDING = "Applicativo sem permissão para gravar audio";

class AudioService {
  FlutterAudioRecorder _recorder;
  Recording _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;

  init(FlutterWebviewPlugin flutterWebviewPlugin) async {
    try {
      if (_isCanWriteInDevice()) {}
      if (_isCanRecordAudio()) {
        _onError(flutterWebviewPlugin, AUDIO_IN_RECORDING);
        return;
      }
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/flutter_audio_recorder_';
        io.Directory appDocDirectory;
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }

        customPath = appDocDirectory.path +
            customPath +
            DateTime.now().millisecondsSinceEpoch.toString();

        _recorder =
            FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);

        await _recorder.initialized;
        var current = await _recorder.current(channel: 0);

        _current = current;
        _currentStatus = current.status;

        start(flutterWebviewPlugin);
      } else {
        _onError(flutterWebviewPlugin, NOT_PERMISSION_RECORDING);
      }
    } catch (e) {
      print(e);
    }
  }

  start(FlutterWebviewPlugin flutterWebviewPlugin) async {
    try {
      await _recorder.start();
      var recording = await _recorder.current(channel: 0);

      _current = recording;

      const tick = const Duration(milliseconds: 50);
      new Timer.periodic(tick, (Timer timer) async {
        await _isActiveWebView(flutterWebviewPlugin, timer);

        if (_currentStatus == RecordingStatus.Stopped) {
          timer.cancel();
        }

        var current = await _recorder.current(channel: 0);
        _current = current;
        _currentStatus = _current.status;
      });
    } catch (e) {
      print(e);
    }
  }

  findStatusRecordingFromJS(FlutterWebviewPlugin flutterWebviewPlugin) async {
    if (_currentStatus == RecordingStatus.Unset ||
        _currentStatus == RecordingStatus.Stopped) {
      await flutterWebviewPlugin.evalJavascript(
          'onRecivedStatusRecording("${JSAudioStatus.Stopped.toString()}")');
      return;
    }

    if (_currentStatus == RecordingStatus.Initialized ||
        _currentStatus == RecordingStatus.Recording) {
      await flutterWebviewPlugin.evalJavascript(
          'onRecivedStatusRecording("${JSAudioStatus.Recording.toString()}")');
      return;
    }

    //TODO implementar enviando
    //Obs.: Falta a API
  }

  stop({isBackgroundApp = false}) async {
    var result = await _recorder.stop();

    print("Stop recording: ${result.path}");
    var file = io.File(result.path);

    if (isBackgroundApp) {
      try {
        await file.delete();
        print("Deleted recording: ${result.path}");
        return;
      } catch (e) {
        return;
      }
    }
    // print("File length: ${await file.length()}");

    _current = result;
    _currentStatus = _current.status;
  }

  void sendingAudioToAPI() async {
    print("Enviando audio para API...");
  }

  void play() async {
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.play(_current.path, isLocal: true);
  }

  RecordingStatus statusRecording() {
    return _currentStatus;
  }

  bool _isCanWriteInDevice() {
    //TODO implementar verificação de gravação
    return true;
  }

  bool _isCanRecordAudio() {
    return _currentStatus != RecordingStatus.Stopped &&
        _currentStatus != RecordingStatus.Unset;
  }

  void _onError(
      FlutterWebviewPlugin flutterWebviewPlugin, String errorMessage) {
    flutterWebviewPlugin.evalJavascript('onErrorFromFlutter("$errorMessage")');
  }

  Future<void> _isActiveWebView(
      FlutterWebviewPlugin flutterWebviewPlugin, Timer timer) async {
    var resultActiveJS = await flutterWebviewPlugin
        .evalJavascript('isActiveWebViewFromFlutter()');
    if (resultActiveJS == null || resultActiveJS == "null") {
      await stop(isBackgroundApp: false);
      timer.cancel();
    }
  }
}

enum JSAudioStatus { Recording, Stopped, Sending }
