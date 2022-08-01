part of flutter_link_preview;

abstract class InfoBase {
  late DateTime _timeout;
}

/// Web Information
class WebInfo extends InfoBase {
  final String? title;
  final String? icon;
  final String? description;
  final String? mediaUrl;
  final String? redirectUrl;

  WebInfo({
    this.title,
    this.icon,
    this.description,
    this.mediaUrl,
    this.redirectUrl,
  });
}

/// Image Information
class WebImageInfo extends WebInfo {
  WebImageInfo({String? mediaUrl}) : super(mediaUrl: mediaUrl);
}

/// Video Information
class WebVideoInfo extends WebInfo {
  WebVideoInfo({String? mediaUrl}) : super(mediaUrl: mediaUrl);
}

/// Video Information
class WebAudioInfo extends WebInfo {
  WebAudioInfo({String? mediaUrl}) : super(mediaUrl: mediaUrl);
}

/// Web analyzer
class WebAnalyzer {
  static final Map<String?, InfoBase> _map = {};
  static final RegExp _bodyReg =
      RegExp(r"<body[^>]*>([\s\S]*?)<\/body>", caseSensitive: false);
  static final RegExp _htmlReg = RegExp(
      r"(<head[^>]*>([\s\S]*?)<\/head>)|(<script[^>]*>([\s\S]*?)<\/script>)|(<style[^>]*>([\s\S]*?)<\/style>)|(<[^>]+>)|(<link[^>]*>([\s\S]*?)<\/link>)|(<[^>]+>)",
      caseSensitive: false);
  static final RegExp _metaReg = RegExp(
      r"<(meta|link)(.*?)\/?>|<title(.*?)</title>",
      caseSensitive: false,
      dotAll: true);
  static final RegExp _titleReg =
      RegExp("(title|icon|description|image)", caseSensitive: false);
  static final RegExp _lineReg = RegExp(r"[\n\r]|&nbsp;|&gt;");
  static final RegExp _spaceReg = RegExp(r"\s+");

  /// Is it an empty string
  static bool isNotEmpty(String? str) {
    return str != null && str.isNotEmpty;
  }

  /// Get web information
  /// return [InfoBase]
  static InfoBase? getInfoFromCache(String? url) {
    final InfoBase? info = _map[url];
    if (info != null) {
      if (!info._timeout.isAfter(DateTime.now())) {
        _map.remove(url);
      }
    }
    return info;
  }

  /// Get web information
  /// return [InfoBase]
  static Future<InfoBase?> getInfo(
    String url, {
    Duration cache = const Duration(hours: 24),
    bool multimedia = true,
    bool useMultithread = false,
    bool useDesktopAgent = true,
    Map<String, String>? customHeader,
  }) async {
    InfoBase? info = getInfoFromCache(url);
    if (info != null) return info;
    try {
      if (useMultithread)
        info = await _getInfoByIsolate(url, multimedia,
            useDesktopAgent: useDesktopAgent);
      else
        info = await _getInfo(
          url,
          multimedia,
          useDesktopAgent: useDesktopAgent,
          customHeader: customHeader,
        );

      if (info != null) {
        info._timeout = DateTime.now().add(cache);
        _map[url] = info;
      }
    } catch (e) {
      print("Get web error:$url, Error:$e");
    }

    return info;
  }

  static Future<InfoBase?> _getInfo(
    String url,
    bool multimedia, {
    useDesktopAgent = true,
    Map<String, String>? customHeader,
  }) async {
    Map<String, dynamic> result = {};
    if (Platform.isIOS) {
      result = await LinkFetch.linkFetchWithFilterLargeFile(
          url: url, encodeUrl: "false");
      if (result.isEmpty) return null;
    } else {
      final response = await _requestUrl(url,
          useDesktopAgent: useDesktopAgent, customHeader: customHeader);
      if (response == null) return null;
      result['content-type'] = response.headers['content-type'] ?? "";
      result['data'] = response.bodyBytes;
      result['status_code'] = response.statusCode;
      result['url'] = response.request?.url.toString() ?? url;
      print("$url ${response.statusCode}");
    }
    if (multimedia) {
      final String? contentType = result["content-type"];
      if (contentType != null) {
        if (contentType.contains("image/")) {
          return WebImageInfo(mediaUrl: url);
        } else if (contentType.contains("video/")) {
          return WebVideoInfo(mediaUrl: url);
        } else if (contentType.contains("audio/")) {
          return WebAudioInfo(mediaUrl: url);
        }
      }
    }

    return _getWebInfo(result, url, multimedia);
  }

  static Future<InfoBase?> _getInfoByIsolate(
    String? url,
    bool multimedia, {
    useDesktopAgent = true,
    Map<String, String>? customHeader,
  }) async {
    final sender = ReceivePort();
    final Isolate isolate = await Isolate.spawn(
      (dynamic sendPort) => _isolate(sendPort,
          useDesktopAgent: useDesktopAgent, customHeader: customHeader),
      sender.sendPort,
    );
    final sendPort = await sender.first as SendPort;
    final answer = ReceivePort();

    sendPort.send([answer.sendPort, url, multimedia]);
    final List<String>? res = await (answer.first as FutureOr<List<String>?>);

    InfoBase? info;
    if (res != null) {
      if (res[0] == "0") {
        info = WebInfo(
            title: res[1], description: res[2], icon: res[3], mediaUrl: res[4]);
      } else if (res[0] == "1") {
        info = WebVideoInfo(mediaUrl: res[1]);
      } else if (res[0] == "2") {
        info = WebImageInfo(mediaUrl: res[1]);
      } else if (res[0] == "4") {
        info = WebAudioInfo(mediaUrl: res[1]);
      }
    }

    sender.close();
    answer.close();
    isolate.kill(priority: Isolate.immediate);

    return info;
  }

  static void _isolate(
    SendPort sendPort, {
    useDesktopAgent = true,
    Map<String, String>? customHeader,
  }) {
    final port = ReceivePort();
    sendPort.send(port.sendPort);
    port.listen((message) async {
      // NOTE: 2022/2/14 此处需要确认运行时状态
      final SendPort sender = message[0];
      final String url = message[1] ?? '';
      final bool multimedia = message[2] ?? false;

      final info = await _getInfo(url, multimedia,
          useDesktopAgent: useDesktopAgent, customHeader: customHeader);

      if (info is WebInfo) {
        sender.send(
            ["0", info.title, info.description, info.icon, info.mediaUrl]);
      } else if (info is WebVideoInfo) {
        sender.send(["1", info.mediaUrl]);
      } else if (info is WebImageInfo) {
        sender.send(["2", info.mediaUrl]);
      } else if (info is WebAudioInfo) {
        sender.send(["4", info.mediaUrl]);
      } else {
        sender.send(null);
      }
      port.close();
    });
  }

  // static final Map<String, String> _cookies = {
  //   "weibo.com":
  //       "YF-Page-G0=02467fca7cf40a590c28b8459d93fb95|1596707497|1596707497; SUB=_2AkMod12Af8NxqwJRmf8WxGjna49_ygnEieKeK6xbJRMxHRl-yT9kqlcftRB6A_dzb7xq29tqJiOUtDsy806R_ZoEGgwS; SUBP=0033WrSXqPxfM72-Ws9jqgMF55529P9D9W59fYdi4BXCzHNAH7GabuIJ",
  //   "m.weibo.cn":
  //       "YF-Page-G0=02467fca7cf40a590c28b8459d93fb95|1596707497|1596707497; SUB=_2AkMod12Af8NxqwJRmf8WxGjna49_ygnEieKeK6xbJRMxHRl-yT9kqlcftRB6A_dzb7xq29tqJiOUtDsy806R_ZoEGgwS; SUBP=0033WrSXqPxfM72-Ws9jqgMF55529P9D9W59fYdi4BXCzHNAH7GabuIJ"
  // };

  static String? _getCookies(String host) {
    if (host.contains("m.weibo.cn")) {
      return "YF-Page-G0=02467fca7cf40a590c28b8459d93fb95|1596707497|1596707497; SUB=_2AkMod12Af8NxqwJRmf8WxGjna49_ygnEieKeK6xbJRMxHRl-yT9kqlcftRB6A_dzb7xq29tqJiOUtDsy806R_ZoEGgwS; SUBP=0033WrSXqPxfM72-Ws9jqgMF55529P9D9W59fYdi4BXCzHNAH7GabuIJ";
    }
    if (host.contains("weibo.com")) {
      return "YF-Page-G0=02467fca7cf40a590c28b8459d93fb95|1596707497|1596707497; SUB=_2AkMod12Af8NxqwJRmf8WxGjna49_ygnEieKeK6xbJRMxHRl-yT9kqlcftRB6A_dzb7xq29tqJiOUtDsy806R_ZoEGgwS; SUBP=0033WrSXqPxfM72-Ws9jqgMF55529P9D9W59fYdi4BXCzHNAH7GabuIJ";
    }
    if (host.contains("feishu.cn")) {
      return "session=U7CK1RF-c09t7d68-96e8-48b1-b4fe-dd9bf5426931-NN5W4";
    }
    return null;
  }

  static bool _certificateCheck(X509Certificate cert, String host, int port) =>
      true;

  static Future<Response?> _requestUrl(String url,
      {int count = 0,
      String? cookie,
      Map<String, String>? customHeader,
      useDesktopAgent = true}) async {
    if (url.contains("m.toutiaoimg.cn")) useDesktopAgent = false;
    if (url.contains("weibo.com") || url.contains("m.weibo.cn"))
      useDesktopAgent = false;
    Response? res;
    final uri = Uri.parse(url);
    final ioClient = HttpClient()..badCertificateCallback = _certificateCheck;
    final client = IOClient(ioClient);
    final request = Request('GET', uri)
      ..followRedirects = false
      ..headers["User-Agent"] = useDesktopAgent
          ? "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.125 Safari/537.36"
          : "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1"
      ..headers["cache-control"] = "no-cache"
      ..headers["Cookie"] = cookie ?? _getCookies(uri.host) ?? ""
      ..headers["accept"] = "*/*"
      ..headers['Host'] = uri.host
      ..headers.addAll(customHeader ?? {});
    // print(request.headers);
    final stream = await client.send(request);

    if (stream.statusCode == HttpStatus.movedTemporarily ||
        stream.statusCode == HttpStatus.movedPermanently ||
        stream.statusCode == HttpStatus.temporaryRedirect) {
      if (stream.isRedirect && count < 6) {
        final String? location = stream.headers['location'];
        if (location != null) {
          url = location;
          if (location.startsWith("//")) {
            url = "${uri.scheme}:$location";
          } else if (location.startsWith("/")) {
            url = uri.origin + location;
          }
        }
        if (stream.headers['set-cookie'] != null) {
          cookie = stream.headers['set-cookie'];
        }
        count++;
        client.close();
        return _requestUrl(url,
            count: count, cookie: cookie, useDesktopAgent: useDesktopAgent);
      }
    } else if (stream.statusCode == HttpStatus.ok) {
      /// 超过 100m 的网页不解析
      final contentLength = stream.headers["content-length"];
      final contentType = stream.headers["content-type"]!;

      if (contentType.contains("image/") ||
          contentType.contains("video/") ||
          contentType.contains("audio/")) {
        client.close();
        return Response("body", stream.statusCode, headers: stream.headers);
      } else if (contentLength?.isNotEmpty ?? false) {
        if (double.parse(contentLength!) > 100 * 1000 * 1000) {
          client.close();
          return null;
        }
      }

      if (contentType.contains("text/html") ||
          contentType.contains("text/asp")) {
        res = await Response.fromStream(stream);
        if (uri.host == "m.tb.cn") {
          final match = RegExp(r"var url = \'(.*)\'").firstMatch(res.body);
          if (match != null) {
            final newUrl = match.group(1);
            if (newUrl != null) {
              return _requestUrl(newUrl,
                  count: count,
                  cookie: cookie,
                  useDesktopAgent: useDesktopAgent);
            }
          }
        }
      }
    }
    client.close();
    if (res == null) print("Get web info empty($url)");
    return res;
  }

  static Future<InfoBase?> _getWebInfo(
      Map<String, dynamic> response, String? url, bool? multimedia) async {
    if (response['status_code'].toString() == HttpStatus.ok.toString()) {
      String? html;
      try {
        html = const Utf8Decoder().convert(response['data']);
      } catch (e) {
        try {
          html = gbk.decode(response['data']);
        } catch (e) {
          print("Web page resolution failure from:$url Error:$e");
        }
      }

      if (html == null) {
        print("Web page resolution failure from:$url");
        return null;
      }

      // Improved performance
      // final start = DateTime.now();
      final headHtml = _getHeadHtml(html);
      final document = parser.parse(headHtml);
      // print("dom cost ${DateTime.now().difference(start).inMilliseconds}");
      final uri = Uri.parse(url!);

      // get image or video
      if (multimedia!) {
        final gif = _analyzeGif(document, uri);
        if (gif != null) return gif;

        final video = _analyzeVideo(document, uri);
        if (video != null) return video;
      }

      String? title = _analyzeTitle(document);
      String? description =
          _analyzeDescription(document, html)?.replaceAll(r"\x0a", " ");
      if (!isNotEmpty(title)) {
        title = description;
        description = null;
      }

      final info = WebInfo(
        title: title,
        icon: _analyzeIcon(document, uri),
        description: description,
        mediaUrl: _analyzeImage(document, uri),
        redirectUrl: response['url'].toString(),
      );
      return info;
    }
    return null;
  }

  static String _getHeadHtml(String html) {
    html = html.replaceFirst(_bodyReg, "<body></body>");
    final matchs = _metaReg.allMatches(html);
    final StringBuffer head = StringBuffer("<html><head>");
    matchs.forEach((element) {
      final String str = element.group(0)!;
      if (str.contains(_titleReg)) head.writeln(str);
    });
    head.writeln("</head></html>");
    return head.toString();
  }

  static InfoBase? _analyzeGif(Document document, Uri uri) {
    if (_getMetaContent(document, "property", "og:image:type") == "image/gif") {
      final gif = _getMetaContent(document, "property", "og:image");
      if (gif != null) return WebImageInfo(mediaUrl: _handleUrl(uri, gif));
    }
    return null;
  }

  static InfoBase? _analyzeVideo(Document document, Uri uri) {
    final video = _getMetaContent(document, "property", "og:video");
    if (video != null) return WebVideoInfo(mediaUrl: _handleUrl(uri, video));
    return null;
  }

  static String? _getMetaContent(
      Document document, String property, String propertyValue) {
    final meta = document.head!.getElementsByTagName("meta");
    final ele =
        meta.firstWhereOrNull((e) => e.attributes[property] == propertyValue);
    if (ele != null) return ele.attributes["content"]?.trim();
    return null;
  }

  static String _analyzeTitle(Document document) {
    final title = _getMetaContent(document, "property", "og:title");
    if (title != null) return title;
    final list = document.head!.getElementsByTagName("title");
    if (list.isNotEmpty) {
      final tagTitle = list.first.text;
      return tagTitle.trim();
    }
    return "";
  }

  static String? _analyzeDescription(Document document, String html) {
    final desc = _getMetaContent(document, "property", "og:description");
    if (desc != null) return desc;

    final description = _getMetaContent(document, "name", "description") ??
        _getMetaContent(document, "name", "Description");

    if (!isNotEmpty(description)) {
      // final DateTime start = DateTime.now();
      String body = html.replaceAll(_htmlReg, "");
      body = body.trim().replaceAll(_lineReg, " ").replaceAll(_spaceReg, " ");
      if (body.length > 300) {
        body = body.substring(0, 300);
      }
      // print("html cost ${DateTime.now().difference(start).inMilliseconds}");
      return body;
    }
    return description;
  }

  static String? _analyzeIcon(Document document, Uri uri) {
    final meta = document.head!.getElementsByTagName("link");
    String? icon = "";
    // get icon first
    var metaIcon = meta.firstWhereOrNull((e) {
      final rel = (e.attributes["rel"] ?? "").toLowerCase();
      if (rel == "icon") {
        icon = e.attributes["href"];
        if (icon != null && !icon!.toLowerCase().contains(".svg")) {
          return true;
        }
      }
      return false;
    });

    metaIcon ??= meta.firstWhereOrNull((e) {
      final rel = (e.attributes["rel"] ?? "").toLowerCase();
      if (rel == "shortcut icon") {
        icon = e.attributes["href"];
        if (icon != null && !icon!.toLowerCase().contains(".svg")) {
          return true;
        }
      }
      return false;
    });

    if (metaIcon != null) {
      icon = metaIcon.attributes["href"];
    } else {
      return "${uri.origin}/favicon.ico";
    }

    return _handleUrl(uri, icon);
  }

  static String? _analyzeImage(Document document, Uri uri) {
    final image = _getMetaContent(document, "property", "og:image");
    return _handleUrl(uri, image);
  }

  static String? _handleUrl(Uri uri, String? source) {
    if (isNotEmpty(source) && !source!.startsWith("http")) {
      if (source.startsWith("//")) {
        source = "${uri.scheme}:$source";
      } else {
        if (source.startsWith("/")) {
          source = "${uri.origin}$source";
        } else {
          source = "${uri.origin}/$source";
        }
      }
    }
    return source;
  }
}
