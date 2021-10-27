import 'dart:async';
import 'dart:collection';
import 'dart:io' as io;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_mp3/record_mp3.dart';
import 'package:http/http.dart' as http;

const ERROR_STOP_RECORDING = "Erro ao tentar parar gravação";
const ERROR_SENDING_RECORDING = "Erro ao tentar enviar a gravação para API";
const ERROR_CANCEL_RECORDING = "Erro ao tentar cancelar a gravação";
const ERROR_ALREADY_RECORDING = "Já existe uma gravação em curso";

const NOT_PERMISSION_RECORDING = "Applicativo sem permissão para gravar audio";

const RECORDING = "Recording";
const STOPPED = "Stopped";
const SENDING = "Sending";

class AudioServiceMP3 {
  bool isComplete = false;
  String recordFilePath;

  stopRecoderAudio(
      {FlutterWebviewPlugin flutterWebviewPlugin,
      String onSentCallback,
      String onStopCallback,
      String onErrorCallback,
      Map<String, dynamic> sendParameters}) async {
    stop(isBackgroundApp: false);
    if (isComplete) {
      flutterWebviewPlugin.evalJavascript('$onStopCallback(true)');
      bool isSent = await _sendingAudioToAPI(sendParameters: sendParameters);
      if (isSent) {
        flutterWebviewPlugin.evalJavascript('$onSentCallback(true)');
      } else {
        flutterWebviewPlugin
            .evalJavascript('$onErrorCallback("$ERROR_SENDING_RECORDING")');
      }
    } else {
      flutterWebviewPlugin
          .evalJavascript('$onErrorCallback("$ERROR_STOP_RECORDING")');
    }
  }

  stop({isBackgroundApp = false}) async {
    RecordMp3.instance.stop();
    isComplete = true;

    if (isBackgroundApp) {
      _deleteRecordedAudioFile();
      return;
    }
  }

  cancelRecoderAudio(
      {FlutterWebviewPlugin flutterWebviewPlugin,
      String onCancelCallback,
      String onErrorCallback}) async {
    stop(isBackgroundApp: true);
    if (isComplete) {
      flutterWebviewPlugin
          .evalJavascript('$onErrorCallback("$ERROR_CANCEL_RECORDING")');
    }
  }

  playRecoderAudio(
      {FlutterWebviewPlugin flutterWebviewPlugin,
      String onCheckerCallback,
      String onPlayCallback,
      String onErrorCallback}) async {
    try {
      bool hasPermissionRecordAndWriteInDevice =
          await _isCanRecordAudioAndWriteInDevice();

      //TODO validar se o audio esta sendo usado por outro app
      if (RecordMp3.instance.status == RecordStatus.RECORDING) {
        flutterWebviewPlugin
            .evalJavascript('$onErrorCallback("$ERROR_ALREADY_RECORDING")');
        return;
      }

      if (hasPermissionRecordAndWriteInDevice) {
        recordFilePath = await _getFilePath();
        RecordMp3.instance.start(recordFilePath, (type) {
          print("Record error---> $type");
          flutterWebviewPlugin
              .evalJavascript('$onErrorCallback("$NOT_PERMISSION_RECORDING")');
        });
        flutterWebviewPlugin.evalJavascript('$onPlayCallback(true)');

        await _startOnChecker(flutterWebviewPlugin, onCheckerCallback);
      } else {
        await flutterWebviewPlugin
            .evalJavascript('$onErrorCallback("$NOT_PERMISSION_RECORDING")');
      }
    } catch (e) {
      print("Error playRecoderAudio--->" + e);
    }
  }

  Future<void> _startOnChecker(flutterWebviewPlugin, onCheckerCallback) async {
    const tick = const Duration(milliseconds: 60);
    new Timer.periodic(tick, (Timer timer) async {
      var onChekerActive =
          await flutterWebviewPlugin.evalJavascript('$onCheckerCallback()');
      if (onChekerActive == null || onChekerActive == "null") {
        await stop(isBackgroundApp: true);
        timer.cancel();
      }

      if (RecordMp3.instance.status == RecordStatus.IDEL) {
        timer.cancel();
      }
    });
  }

  String getSituation() {
    if (RecordMp3.instance.status == RecordStatus.RECORDING) {
      return RECORDING;
    }
    return STOPPED;
  }

  void playAudio() async {
    if (recordFilePath != null && io.File(recordFilePath).existsSync()) {
      AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.play(recordFilePath, isLocal: true);
    } else {
      recordFilePath = null;
    }
  }

  RecordStatus statusRecording() {
    return RecordMp3.instance.status;
  }

  Future<String> _getFilePath() async {
    String customPath = '/audio_recorder_';
    io.Directory appDocDirectory;
    if (io.Platform.isIOS) {
      appDocDirectory = await getApplicationDocumentsDirectory();
    } else {
      appDocDirectory = await getApplicationDocumentsDirectory();
    }
    return appDocDirectory.path +
        customPath +
        DateTime.now().millisecondsSinceEpoch.toString() +
        ".mp3";
  }

  _sendingAudioToAPI({Map<String, dynamic> sendParameters}) async {
    print("Enviando audio para API...");
    var response;
    String method = sendParameters["method"];
    Map<String, String> headers = HashMap();
    sendParameters["header"].forEach((k, v) => {headers[k] = v});

    var uri = Uri.parse(sendParameters["url"]);
    var request = http.MultipartRequest(method, uri)
      ..headers.addAll(headers)
      ..files.add(await http.MultipartFile.fromPath("file", recordFilePath));

    try {
      response = await request.send();
    } catch (e) {
      print("Error ao enviar para API ---->" + e.toString());
      return false;
    }
    _deleteRecordedAudioFile();
    return response.statusCode == 200;
  }

  _deleteRecordedAudioFile() async {
    try {
      if (await io.File(recordFilePath).exists()) {
        await io.File(recordFilePath).delete();
      }
      print("Deleted recording: " + recordFilePath);
    } catch (e) {
      print("Error ao deletar gravação---->" + e.toString());
    }
    return;
  }

  Future<bool> _isCanRecordAudioAndWriteInDevice() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }
}
