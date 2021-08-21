import 'dart:async';
import 'dart:io' as io;

import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_mp3/record_mp3.dart';

const ERROR_RECORD = "Erro interno ao gravar o audio";
const AUDIO_IN_RECORDING = "Audio já esta em gravação";
const NOT_PERMISSION_RECORDING = "Applicativo sem permissão para gravar audio";

const RECORDING = "Recording";
const STOPPED = "Stopped";
const SENDING = "Sending";

class AudioServiceMP3 {
  bool isComplete = false;
  String recordFilePath;

  init(FlutterWebviewPlugin flutterWebviewPlugin) async {
    try {
      bool hasPermissionRecordAndWriteInDevice =
          await isCanRecordAudioAndWriteInDevice();
      // if (_isCanRecordAudio()) {
      //   _onError(flutterWebviewPlugin, AUDIO_IN_RECORDING);
      //   return;
      // }
      if (hasPermissionRecordAndWriteInDevice) {
        recordFilePath = await _getFilePath();
        RecordMp3.instance.start(recordFilePath, (type) {
          print("Record error--->$type");
          _onError(flutterWebviewPlugin, ERROR_RECORD);
        });

        const tick = const Duration(milliseconds: 50);
        new Timer.periodic(tick, (Timer timer) async {
          await _isActiveWebView(flutterWebviewPlugin, timer);

          if (RecordMp3.instance.status == RecordStatus.IDEL) {
            timer.cancel();
          }
        });
      } else {
        _onError(flutterWebviewPlugin, NOT_PERMISSION_RECORDING);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<String> _getFilePath() async {
    String customPath = '/audio_recorder_';
    io.Directory appDocDirectory;
    if (io.Platform.isIOS) {
      appDocDirectory = await getApplicationDocumentsDirectory();
    } else {
      appDocDirectory = await getExternalStorageDirectory();
    }
    return appDocDirectory.path +
        customPath +
        DateTime.now().millisecondsSinceEpoch.toString() +
        ".mp3";
  }

  findStatusRecordingFromJS(FlutterWebviewPlugin flutterWebviewPlugin) async {
    if (RecordMp3.instance.status == RecordStatus.IDEL) {
      await flutterWebviewPlugin
          .evalJavascript('onRecivedStatusRecording("$STOPPED")');
      return;
    }

    if (RecordMp3.instance.status == RecordStatus.RECORDING) {
      await flutterWebviewPlugin
          .evalJavascript('onRecivedStatusRecording("$RECORDING")');
      return;
    }

    //TODO implementar enviando
    //Obs.: Falta a API
  }

  String getSituation() {
    if (RecordMp3.instance.status == RecordStatus.RECORDING) {
      return RECORDING;
    }
    return STOPPED;
  }

  stop({isBackgroundApp = false}) async {
    bool s = RecordMp3.instance.stop();
    if (s) {
      isComplete = true;
    } else {
      //TODO tratar
    }

    if (isBackgroundApp) {
      try {
        await io.File(recordFilePath).delete();
        print("Deleted recording: " + recordFilePath);
        return;
      } catch (e) {
        return;
      }
    }
  }

  void sendingAudioToAPI() async {
    print("Enviando audio para API...");
  }

  void play() async {
    if (recordFilePath != null && io.File(recordFilePath).existsSync()) {
      AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.play(recordFilePath, isLocal: true);
    }
  }

  RecordStatus statusRecording() {
    return RecordMp3.instance.status;
  }

  Future<bool> isCanRecordAudioAndWriteInDevice() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
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
      await stop(isBackgroundApp: true);
      timer.cancel();
    }
  }
}
