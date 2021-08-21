import 'dart:convert';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:myapp/service/audio_service_mp3.dart';
import 'package:myapp/webview/webview_channel_controller.dart';

class PlayAudioRecorder implements WebViewJSChannelController {
  FlutterWebviewPlugin _flutterWebviewPlugin;
  AudioServiceMP3 _audioService;

  PlayAudioRecorder(
      FlutterWebviewPlugin flutterWebviewPlugin, AudioServiceMP3 audioService) {
    _flutterWebviewPlugin = flutterWebviewPlugin;
    _audioService = audioService;
  }

  @override
  JavascriptChannel getChannel() {
    return JavascriptChannel(
      name: 'PlayRecorderAudioJS',
      onMessageReceived: _onMessage,
    );
  }

  void _onMessage(JavascriptMessage message) async {
    Map messageJson = json.decode(message.message);

    await _audioService.playRecoderAudio(
        flutterWebviewPlugin: _flutterWebviewPlugin,
        onCheckerCallback: messageJson["onChecker"],
        onErrorCallback: messageJson["onError"],
        onPlayCallback: messageJson["onCalback"]);
  }
}
