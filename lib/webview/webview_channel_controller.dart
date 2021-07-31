import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class ChannelController {
  static Set<JavascriptChannel> getChannels(
      FlutterWebviewPlugin flutterWebviewPlugin) {
    _TakePhotograph takePhoto = _TakePhotograph(flutterWebviewPlugin);

    return Set.from(
      [takePhoto.getChannel()],
    );
  }
}

class _TakePhotograph implements WebViewJSChannelController {
  FlutterWebviewPlugin _flutterWebviewPlugin;

  _TakePhotograph(FlutterWebviewPlugin flutterWebviewPlugin) {
    _flutterWebviewPlugin = flutterWebviewPlugin;
  }

  File _storedImage;

  _takePicture() async {
    final ImagePicker _picker = ImagePicker();
    PickedFile imageFile =
        await _picker.getImage(source: ImageSource.camera, maxWidth: 600);
    if (imageFile == null) return;

    _storedImage = File(imageFile.path);

    final bytesFromImage = File(_storedImage.path).readAsBytesSync();
    String img64 = base64Encode(bytesFromImage);

    _flutterWebviewPlugin.evalJavascript('alertValueFromFlutter("$img64")');
    _flutterWebviewPlugin.show();
  }

  @override
  JavascriptChannel getChannel() {
    return JavascriptChannel(
        name: 'Print',
        onMessageReceived: (JavascriptMessage message) {
          _flutterWebviewPlugin.hide();
          _takePicture();
        });
  }
}

abstract class WebViewJSChannelController {
  JavascriptChannel getChannel();
}
