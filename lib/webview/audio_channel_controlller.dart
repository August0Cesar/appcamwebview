import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:myapp/webview/webview_channel_controller.dart';
import 'package:path_provider/path_provider.dart';

class AudioChannelController implements WebViewJSChannelController {
  FlutterWebviewPlugin _flutterWebviewPlugin;
  FlutterAudioRecorder _recorder;
  Recording _current;
  RecordingStatus _currentStatus = RecordingStatus.Unset;

  AudioChannelController(FlutterWebviewPlugin flutterWebviewPlugin) {
    _flutterWebviewPlugin = flutterWebviewPlugin;
  }
  @override
  JavascriptChannel getChannel() {
    return JavascriptChannel(
        name: 'AudioJSChannel', onMessageReceived: _onMessage);
  }

  void _onMessage(JavascriptMessage message) async {
    if (message.message == 'START_RECORD') {
      _init();
      return;
    }

    if (message.message == 'STOP_RECORD') {
      _stop();
      return;
    }

    if (message.message == 'PLAY_RECORD') {
      _play();
      return;
    }
  }

  _init() async {
    try {
      if (await FlutterAudioRecorder.hasPermissions) {
        String customPath = '/flutter_audio_recorder_';
        io.Directory appDocDirectory;
//        io.Directory appDocDirectory = await getApplicationDocumentsDirectory();
        if (io.Platform.isIOS) {
          appDocDirectory = await getApplicationDocumentsDirectory();
        } else {
          appDocDirectory = await getExternalStorageDirectory();
        }

        // can add extension like ".mp4" ".wav" ".m4a" ".aac"
        customPath = appDocDirectory.path +
            customPath +
            DateTime.now().millisecondsSinceEpoch.toString();

        // .wav <---> AudioFormat.WAV
        // .mp4 .m4a .aac <---> AudioFormat.AAC
        // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.
        _recorder =
            FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);

        await _recorder.initialized;
        // after initialization
        var current = await _recorder.current(channel: 0);
        print(current);
        // should be "Initialized", if all working fine

        _current = current;
        _currentStatus = current.status;
        print(_currentStatus);
        _start();
      } else {
        print("You must accept permissions");
      }
    } catch (e) {
      print(e);
    }
  }

  _start() async {
    try {
      await _recorder.start();
      var recording = await _recorder.current(channel: 0);

      _current = recording;

      const tick = const Duration(milliseconds: 50);
      new Timer.periodic(tick, (Timer t) async {
        var result_js =
            await _flutterWebviewPlugin.evalJavascript('isActiveWebView()');
        print(result_js);

        if (result_js == null || result_js == "null") {
          await _stop();
          t.cancel();
        }
        if (_currentStatus == RecordingStatus.Stopped) {
          t.cancel();
        }

        var current = await _recorder.current(channel: 0);
        // print(current.status);

        _current = current;
        _currentStatus = _current.status;
      });
    } catch (e) {
      print(e);
    }
  }

  _stop() async {
    var result = await _recorder.stop();
    print("Stop recording: ${result.path}");
    print("Stop recording: ${result.duration}");
    // File file = widget.localFileSystem.file(result.path);
    var file = io.File(result.path);
    print("File length: ${await file.length()}");

    _current = result;
    _currentStatus = _current.status;
  }

  void _play() async {
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.play(_current.path, isLocal: true);
  }
}
