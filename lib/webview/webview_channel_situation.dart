import 'dart:convert';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:myapp/service/audio_service_mp3.dart';
import 'package:myapp/webview/webview_channel_controller.dart';

class GetSituation implements WebViewJSChannelController {
  FlutterWebviewPlugin _flutterWebviewPlugin;
  AudioServiceMP3 _audioService;

  GetSituation(
      FlutterWebviewPlugin flutterWebviewPlugin, AudioServiceMP3 audioService) {
    _flutterWebviewPlugin = flutterWebviewPlugin;
    _audioService = audioService;
  }

  @override
  JavascriptChannel getChannel() {
    return JavascriptChannel(
        name: 'GetSituationJS', onMessageReceived: _onMessage);
  }

  void _onMessage(JavascriptMessage message) async {
    var messageJson = json.decode(message.message);
    String callbackFunction = messageJson["onCalback"];

    var situation = _audioService.getSituation();

    await _flutterWebviewPlugin
        .evalJavascript('$callbackFunction("$situation")');
  }
}
