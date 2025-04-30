import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tabby_flutter_inapp_sdk/tabby_flutter_inapp_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';

const tabbyColor = Color.fromRGBO(62, 237, 191, 1);

typedef TabbyCheckoutCompletion = void Function(WebViewResult resultCode);

class TabbyWebView extends StatefulWidget {
  const TabbyWebView({
    required this.webUrl,
    required this.onResult,
    Key? key,
  }) : super(key: key);

  final String webUrl;
  final TabbyCheckoutCompletion onResult;

  @override
  State<TabbyWebView> createState() => _TabbyWebViewState();

  static void showWebView({
    required BuildContext context,
    required String webUrl,
    required TabbyCheckoutCompletion onResult,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.94,
          child: TabbyWebView(
            webUrl: webUrl,
            onResult: onResult,
          ),
        );
      },
    );
  }
}

extension TabbyPermissionResourceType on WebViewPermissionResourceType {
  static Permission? toAndroidPermission(WebViewPermissionResourceType value) {
    if (value == WebViewPermissionResourceType.camera) {
      return Permission.camera;
    } else if (value == WebViewPermissionResourceType.microphone) {
      return Permission.microphone;
    } else {
      return null;
    }
  }
}

class _TabbyWebViewState extends State<TabbyWebView> {
  final GlobalKey webViewKey = GlobalKey();
  double _progress = 0;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController(
      onPermissionRequest: (request) async {
        final resources = request.platform.types.toList();
        if (resources.isEmpty) {
          return;
        }

        final permissions = Platform.isAndroid
            ? resources
                .map((r) {
                  final permission =
                      TabbyPermissionResourceType.toAndroidPermission(r);
                  return permission;
                })
                .whereType<Permission>()
                .toList()
            : [Permission.camera, Permission.microphone];
        final statuses = await permissions.request();
        final isGranted = statuses.values.every((s) => s.isGranted);
        final future = isGranted ? request.grant : request.deny;
        await future();
      },
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setOnConsoleMessage((message) {
        if (kDebugMode) {
          print('console.log: ${message.message}');
        }
      })
      ..addJavaScriptChannel('tabbyMobileSDK', onMessageReceived: (message) {
        if (kDebugMode) {
          print('Got message from JS: ${message.message}');
        }
        javaScriptHandler(message.message, widget.onResult);
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.webUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_progress < 1) ...[
          LinearProgressIndicator(
            value: _progress,
            color: tabbyColor,
            backgroundColor: Colors.black,
          )
        ],
        Expanded(
          key: webViewKey,
          child: WebViewWidget(
            controller: _webViewController,
          ),
        ),
      ],
    );
  }
}
