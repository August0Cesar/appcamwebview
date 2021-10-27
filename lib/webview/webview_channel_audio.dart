import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:myapp/service/audio_service_mp3.dart';
import 'package:myapp/webview/webview_channel_controller.dart';

class AudioChannelController implements WebViewJSChannelController {
  AudioServiceMP3 _audioService;

  AudioChannelController(AudioServiceMP3 audioService) {
    _audioService = audioService;
  }
  @override
  JavascriptChannel getChannel() {
    return JavascriptChannel(
        name: 'AudioJSChannel', onMessageReceived: _onMessage);
  }

  void _onMessage(JavascriptMessage message) async {
    if (message.message == 'PLAY_RECORD') {
      _audioService.playAudio();
      return;
    }
  }
}
