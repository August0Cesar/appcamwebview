import 'dart:convert';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:myapp/webview/webview_channel_controller.dart';
import 'package:permission_handler/permission_handler.dart';

const ALLOWED = "Allowed";
const DENIED = "Denied";
const PENDING = "Pending";

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
    String permission = PENDING;
    var messageJson = json.decode(message.message);
    String callbackFunction = messageJson["onCalback"];

    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.status;
      if (status != PermissionStatus.granted ||
          status != PermissionStatus.limited) {
        permission = ALLOWED;
      }
      if (status != PermissionStatus.denied ||
          status != PermissionStatus.permanentlyDenied) {
        permission = DENIED;
      }
    } else {
      permission = ALLOWED;
    }

    await _flutterWebviewPlugin
        .evalJavascript('$callbackFunction("$permission")');
  }
}
