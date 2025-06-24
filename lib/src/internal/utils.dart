import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tabby_flutter_inapp_sdk/tabby_flutter_inapp_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';

void printError(Object error, StackTrace stackTrace) {
  debugPrint('Exception: $error');
  debugPrint('StackTrace: $stackTrace');
}

void javaScriptHandler(
  String message,
  TabbyCheckoutCompletion onResult,
) {
  final results = WebViewResult.values
      .where(
        (value) => value.name == message.toLowerCase(),
      )
      .toList();
  if (results.isEmpty) {
    return;
  }

  final resultCode = results.first;
  onResult(resultCode);
}

List<String> getLocalStrings({
  required String price,
  required Currency currency,
  required Lang lang,
}) {
  final fullPrice =
      (double.parse(price) / 4).toStringAsFixed(currency.decimals);
  if (lang == Lang.ar) {
    return [
      'أو قسّمها على 4 دفعات شهرية بقيمة ',
      fullPrice,
      ' ${currency.displayName} ',
      'بدون رسوم أو فوائد. ',
      'لمعرفة المزيد'
    ];
  } else {
    return [
      'or 4 interest-free payments of ',
      fullPrice,
      ' ${currency.displayName}',
      '. ',
      'Learn more'
    ];
  }
}

const space = ' ';

List<String> getLocalStringsNonStandard({
  required Currency currency,
  required Lang lang,
}) {
  if (lang == Lang.ar) {
    return [
      'قسّم مشترياتك وادفعها على كيفك. بدون أي فوائد، أو رسوم.',
      space,
      'لمعرفة المزيد'
    ];
  } else {
    return [
      'Split your purchase and pay over time. No interest. No fees.',
      space,
      'Learn more'
    ];
  }
}

const tabbyRejectionTextEn =
    // ignore: lines_longer_than_80_chars
    'Sorry, Tabby is unable to approve this purchase. Please use an alternative payment method for your order.';
const tabbyRejectionTextAr =
    // ignore: lines_longer_than_80_chars
    'نأسف، تابي غير قادرة على الموافقة على هذه العملية. الرجاء استخدام طريقة دفع أخرى';

String getPrice({
  required String price,
  required Currency currency,
}) {
  final installmentPrice =
      (double.parse(price) / 4).toStringAsFixed(currency.decimals);
  return installmentPrice;
}

WebViewController createBaseWebViewController(
  void Function(JavaScriptMessage) bridgeMessagesHandler,
) {
  return WebViewController(
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
    ..setBackgroundColor(Colors.transparent)
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..addJavaScriptChannel(
      TabbySDK.jsBridgeName,
      onMessageReceived: (message) {
        if (kDebugMode) {
          log(
            'Got message from JS '
            '[${TabbySDK.jsBridgeName}]: '
            '${message.message}',
          );
        }
        bridgeMessagesHandler(message);
      },
    );
}
