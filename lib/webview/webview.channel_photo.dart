import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:myapp/webview/webview_channel_controller.dart';

class TakePhotograph implements WebViewJSChannelController {
  FlutterWebviewPlugin _flutterWebviewPlugin;

  TakePhotograph(FlutterWebviewPlugin flutterWebviewPlugin) {
    _flutterWebviewPlugin = flutterWebviewPlugin;
  }

  File _storedImage;

  @override
  JavascriptChannel getChannel() {
    return JavascriptChannel(
        name: 'Print',
        onMessageReceived: (JavascriptMessage message) {
          _flutterWebviewPlugin.hide();
          _takePicture();
        });
  }

  _takePicture() async {
    final ImagePicker _picker = ImagePicker();
    PickedFile imageFile =
        await _picker.getImage(source: ImageSource.camera, maxWidth: 600);
    if (imageFile == null) return;

    _storedImage = File(imageFile.path);

    final bytesFromImage = File(_storedImage.path).readAsBytesSync();
    String img64 = base64Encode(bytesFromImage);

    await _flutterWebviewPlugin
        .evalJavascript('onReceivedImageFromFlutter("$img64")');
    _flutterWebviewPlugin.show();
  }
}
