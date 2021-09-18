import 'dart:convert';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:myapp/webview/webview_channel_controller.dart';
import 'package:permission_handler/permission_handler.dart';

const ALLOWED = 1;
const DENIED = 0;
const NOT_REQUEST = -1;

class GetPermission implements WebViewJSChannelController {
  FlutterWebviewPlugin _flutterWebviewPlugin;

  GetPermission(FlutterWebviewPlugin flutterWebviewPlugin) {
    _flutterWebviewPlugin = flutterWebviewPlugin;
  }

  @override
  JavascriptChannel getChannel() {
    return JavascriptChannel(
        name: 'GetPermissionJS', onMessageReceived: _onMessage);
  }

  void _onMessage(JavascriptMessage message) async {
    int permission = NOT_REQUEST;
    var messageJson = json.decode(message.message);
    String callbackFunction = messageJson["onCalback"];

    PermissionStatus status = await Permission.microphone.status;
    if (!await Permission.microphone.isGranted) {
      if (status == PermissionStatus.denied ||
          status == PermissionStatus.permanentlyDenied) {
        permission = DENIED;
      }
    } else {
      permission = ALLOWED;
    }

    await _flutterWebviewPlugin
        .evalJavascript('$callbackFunction("$permission")');
  }
}
