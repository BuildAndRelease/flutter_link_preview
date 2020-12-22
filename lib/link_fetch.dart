import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LinkFetch {
  static const MethodChannel _channel = MethodChannel("link_fetch");

  static Future<Map<String, dynamic>> linkFetch({@required String url}) async {
    try {
      final result = await _channel
          .invokeMethod("linkFetch", <String, dynamic>{"url": url ?? ""});
      return <String, dynamic>{
        'data': result['data'],
        'content-type': result['content-type'],
        "error": result['error'],
        'status_code': result['status_code'],
        'url': result['url'],
      };
    } catch (e) {
      print(e.toString());
    }
    return null;
  }
}
