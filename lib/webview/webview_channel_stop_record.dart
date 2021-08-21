import 'dart:convert';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:myapp/service/audio_service_mp3.dart';
import 'package:myapp/webview/webview_channel_controller.dart';

class StopAudioRecorder implements WebViewJSChannelController {
  FlutterWebviewPlugin _flutterWebviewPlugin;
  AudioServiceMP3 _audioService;

  StopAudioRecorder(
      FlutterWebviewPlugin flutterWebviewPlugin, AudioServiceMP3 audioService) {
    _flutterWebviewPlugin = flutterWebviewPlugin;
    _audioService = audioService;
  }

  @override
  JavascriptChannel getChannel() {
    return JavascriptChannel(
      name: 'StopAudioRecordJS',
      onMessageReceived: _onMessage,
    );
  }

  void _onMessage(JavascriptMessage message) async {
    Map messageJson = json.decode(message.message);

    await _audioService.stopRecoderAudio(
        flutterWebviewPlugin: _flutterWebviewPlugin,
        onErrorCallback: messageJson["onError"],
        onSentCallback: messageJson["onSent"],
        onStopCallback: messageJson["onCalback"],
        sendParameters: messageJson["sendParameter"]);
  }
}
