import Flutter
import UIKit
import Photos

public class SwiftLinkFetchPlugin: NSObject, FlutterPlugin, UIAlertViewDelegate, URLSessionDataDelegate {
    var controller: UIViewController!
    var imagesResult: FlutterResult?
    var messenger: FlutterBinaryMessenger;

    init(cont: UIViewController, messenger: FlutterBinaryMessenger) {
        self.controller = cont;
        self.messenger = messenger;
        super.init();
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "link_fetch", binaryMessenger: registrar.messenger())

        let app =  UIApplication.shared
        let rootController = app.delegate!.window!!.rootViewController
        var flutterController: FlutterViewController? = nil
        if rootController is FlutterViewController {
            flutterController = rootController as? FlutterViewController
        } else if app.delegate is FlutterAppDelegate {
            if (app.delegate?.responds(to: Selector(("flutterEngine"))))! {
                let engine: FlutterEngine? = app.delegate?.perform(Selector(("flutterEngine")))?.takeRetainedValue() as? FlutterEngine
                flutterController = engine?.viewController
            }
        }
        let controller : UIViewController = flutterController ?? rootController!;
        let instance = SwiftLinkFetchPlugin.init(cont: controller, messenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as! Dictionary<String, AnyObject>
        let url = (arguments["url"] as? String) ?? ""
        switch (call.method) {
        case "linkFetch":
            fetchLinkInfo(url: url) { (dictionary) in
                result(dictionary)
            }
            break
        case "linkFetchWithFilterLargeFile":
            let linkFetch = LinkFetchWithFilterLargeFile(url: url) { (dictionary) in
                result(dictionary)
            }
            linkFetch.fetch()
            break
        case "linkFetchHead":
            let linkHeaderFetch = LinkFetchHeader(url: url) { (dictionary) in
                result(dictionary)
            }
            linkHeaderFetch.fetch()
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func fetchLinkInfo(url : String, completionHandler : @escaping (Dictionary<String, Any>) -> Void) {
        guard let url = URL(string: url.urlEncoded()) else {
            completionHandler(Dictionary<String, Any>())
            return
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5.0)
        request.httpMethod = "GET"
        request.addValue("no-cache", forHTTPHeaderField: "cache-control")
        request.addValue("*/*", forHTTPHeaderField: "accept")
        if (url.host ?? "").contains("weibo.com") {
            request.addValue("YF-Page-G0=02467fca7cf40a590c28b8459d93fb95|1596707497|1596707497; SUB=_2AkMod12Af8NxqwJRmf8WxGjna49_ygnEieKeK6xbJRMxHRl-yT9kqlcftRB6A_dzb7xq29tqJiOUtDsy806R_ZoEGgwS; SUBP=0033WrSXqPxfM72-Ws9jqgMF55529P9D9W59fYdi4BXCzHNAH7GabuIJ", forHTTPHeaderField: "Cookie")
            request.addValue("Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        }else {
            request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.125 Safari/537.36", forHTTPHeaderField: "User-Agent")
        }
        request.httpShouldHandleCookies = true
        request.timeoutInterval = 5
        let sessionTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            completionHandler(["data":data ?? Data(), "content-type": (response?.mimeType ?? ""), "url" :response?.url?.absoluteString ?? "", "status_code": "200", "error": ""])
        }
        sessionTask.resume()
    }
}
