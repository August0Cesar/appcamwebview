import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:myapp/service/service_audio.dart';
import 'package:myapp/webview/webview_channel_controller.dart';

class AudioChannelController implements WebViewJSChannelController {
  FlutterWebviewPlugin _flutterWebviewPlugin;
  AudioService _audioService;

  AudioChannelController(
      FlutterWebviewPlugin flutterWebviewPlugin, AudioService audioService) {
    _flutterWebviewPlugin = flutterWebviewPlugin;
    _audioService = audioService;
  }
  @override
  JavascriptChannel getChannel() {
    return JavascriptChannel(
        name: 'AudioJSChannel', onMessageReceived: _onMessage);
  }

  void _onMessage(JavascriptMessage message) async {
    if (message.message == 'STATUS_RECORD') {
      _audioService.findStatusRecordingFromJS(_flutterWebviewPlugin);
      return;
    }

    if (message.message == 'START_RECORD') {
      _audioService.init(_flutterWebviewPlugin);
      return;
    }

    if (message.message == 'STOP_RECORD') {
      _audioService.stop(isBackgroundApp: false);
      return;
    }

    if (message.message == 'PLAY_RECORD') {
      _audioService.play();
      return;
    }
  }
}
