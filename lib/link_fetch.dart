import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LinkFetch {
  static const MethodChannel _channel = MethodChannel("link_fetch");

  // 过滤大文件，过滤非文本数据
  static Future<Map<String, dynamic>> linkFetch({@required String url}) async {
    try {
      final result = await _channel
          .invokeMethod("linkFetch", <String, dynamic>{"url": url ?? ""});
      return <String, dynamic>{
        'data': result['data'] ?? Uint8List(0),
        'content-type': result['content-type'] ?? "",
        "error": result['error'] ?? "",
        'status_code': result['status_code'] ?? "",
        'url': result['url'] ?? "",
      };
    } catch (e) {
      print(e.toString());
    }
    return null;
  }

  // 不过滤任何信息，直接获取消息体
  static Future<Map<String, dynamic>> linkFetchDirect(
      {@required String url}) async {
    try {
      final result = await _channel
          .invokeMethod("linkFetchDirect", <String, dynamic>{"url": url ?? ""});
      return <String, dynamic>{
        'data': result['data'] ?? Uint8List(0),
        'content-type': result['content-type'] ?? "",
        "error": result['error'] ?? "",
        'status_code': result['status_code'] ?? "",
        'url': result['url'] ?? "",
      };
    } catch (e) {
      print(e.toString());
    }
    return null;
  }
}
