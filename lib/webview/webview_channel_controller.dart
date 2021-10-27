import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:myapp/service/audio_service_mp3.dart';
import 'package:myapp/webview/webview.channel_photo.dart';

import 'package:myapp/webview/webview_channel_audio.dart';
import 'package:myapp/webview/webview_channel_cancel_record.dart';
import 'package:myapp/webview/webview_channel_permission.dart';
import 'package:myapp/webview/webview_channel_play_record.dart';
import 'package:myapp/webview/webview_channel_situation.dart';
import 'package:myapp/webview/webview_channel_stop_record.dart';

class ChannelController {
  static Set<JavascriptChannel> getChannels(
      FlutterWebviewPlugin flutterWebviewPlugin, AudioServiceMP3 audioService) {
    // TakePhotograph takePhoto = TakePhotograph(flutterWebviewPlugin);
    AudioChannelController audioChannel = AudioChannelController(audioService);

    //Novos Channels
    StopAudioRecorder stopAudioRecorder =
        StopAudioRecorder(flutterWebviewPlugin, audioService);
    PlayAudioRecorder playAudioRecorder =
        PlayAudioRecorder(flutterWebviewPlugin, audioService);
    CancelAudioRecorder cancelAudioRecorder =
        CancelAudioRecorder(flutterWebviewPlugin, audioService);
    GetPermission getPermission = GetPermission(flutterWebviewPlugin);
    GetSituation getSituation =
        GetSituation(flutterWebviewPlugin, audioService);

    return Set.from(
      [
        // takePhoto.getChannel(),
        audioChannel.getChannel(),

        //Novos Channels
        getSituation.getChannel(),
        getPermission.getChannel(),
        playAudioRecorder.getChannel(),
        stopAudioRecorder.getChannel(),
        cancelAudioRecorder.getChannel()
      ],
    );
  }
}

abstract class WebViewJSChannelController {
  JavascriptChannel getChannel();
}
