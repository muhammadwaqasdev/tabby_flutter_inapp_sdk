import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:tabby_flutter_inapp_sdk/src/internal/fixtures.dart';
import 'package:tabby_flutter_inapp_sdk/tabby_flutter_inapp_sdk.dart';

void printError(Object error, StackTrace stackTrace) {
  debugPrint('Exception: $error');
  debugPrint('StackTrace: $stackTrace');
}

NavigationResponseAction navigationResponseHandler({
  required TabbyCheckoutCompletion onResult,
  required String nextUrl,
}) {
  if (nextUrl.contains(defaultMerchantUrls.cancel)) {
    onResult(WebViewResult.close);
    return NavigationResponseAction.CANCEL;
  }
  if (nextUrl.contains(defaultMerchantUrls.failure)) {
    onResult(WebViewResult.rejected);
    return NavigationResponseAction.CANCEL;
  }
  if (nextUrl.contains(defaultMerchantUrls.success)) {
    onResult(WebViewResult.authorized);
    return NavigationResponseAction.CANCEL;
  }
  return NavigationResponseAction.ALLOW;
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
