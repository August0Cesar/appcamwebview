import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:myapp/service/service_audio.dart';
import 'package:myapp/webview/webview.channel_photo.dart';

import 'package:myapp/webview/webview_channel_audio.dart';

class ChannelController {
  static Set<JavascriptChannel> getChannels(
      FlutterWebviewPlugin flutterWebviewPlugin, AudioService audioService) {
    TakePhotograph takePhoto = TakePhotograph(flutterWebviewPlugin);
    AudioChannelController audioChannel =
        AudioChannelController(flutterWebviewPlugin, audioService);

    return Set.from(
      [
        takePhoto.getChannel(),
        audioChannel.getChannel(),
      ],
    );
  }
}

abstract class WebViewJSChannelController {
  JavascriptChannel getChannel();
}
