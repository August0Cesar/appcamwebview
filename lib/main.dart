import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'webview/webview_channel_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const sultsColor = Color(0xFF00CDAC);

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MyApp',
        theme: ThemeData(primaryColor: sultsColor),
        home: MyHomePage(
          title: 'MyApp',
        ));
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final flutterWebviewPlugin = new FlutterWebviewPlugin();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    flutterWebviewPlugin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    flutterWebviewPlugin.onStateChanged.listen((WebViewStateChanged state) {
      if (state.type == WebViewState.finishLoad) {
        print('carregado');
        print('onStateChanged ' + state.type.toString());
      }
    });

    String url = 'https://august0cesar.github.io';

    var wvs = WebviewScaffold(
      url: url,
      geolocationEnabled: true,
      supportMultipleWindows: false,
      allowFileURLs: true,
      withZoom: true,
      withOverviewMode: true,
      withLocalStorage: true,
      hidden: true,
      ignoreSSLErrors: true,

      clearCookies: false,

      enableAppScheme: true,
      appCacheEnabled: true,
      clearCache: true,

      //debuggingEnabled:true,

      javascriptChannels: ChannelController.getChannels(
        flutterWebviewPlugin,
      ),
      initialChild: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("Carregando Configurações"),
              Image.asset(
                "imagens/preloader.gif",
                height: 125.0,
                width: 125.0,
              ),
            ],
          ),
        ),
      ),
    );

    return SafeArea(child: wvs);
  }
}
