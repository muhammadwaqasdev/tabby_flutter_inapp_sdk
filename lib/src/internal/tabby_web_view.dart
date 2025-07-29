import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tabby_flutter_inapp_sdk/tabby_flutter_inapp_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';

const tabbyColor = Color.fromRGBO(62, 237, 191, 1);

typedef TabbyCheckoutCompletion = void Function(WebViewResult resultCode);

class TabbyWebView extends StatefulWidget {
  const TabbyWebView({required this.webUrl, required this.onResult, Key? key})
    : super(key: key);

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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.94,
          minChildSize: 0.5,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return _KeyboardResponsiveBottomSheet(
              child: TabbyWebView(webUrl: webUrl, onResult: onResult),
            );
          },
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
  late WebViewController webViewController;

  @override
  void initState() {
    super.initState();
    webViewController = createBaseWebViewController((message) {
      javaScriptHandler(message.message, widget.onResult);
    });
    webViewController.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          setState(() {
            _progress = progress / 100;
          });
        },
      ),
    );
    webViewController.loadRequest(Uri.parse(widget.webUrl));
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
          ),
        ],
        Expanded(
          key: webViewKey,
          child: WebViewWidget(controller: webViewController),
        ),
      ],
    );
  }
}

class _KeyboardResponsiveBottomSheet extends StatelessWidget {
  final Widget child;

  const _KeyboardResponsiveBottomSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: child,
      ),
    );
  }
}
