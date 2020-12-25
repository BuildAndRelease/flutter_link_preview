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
        let url = URL(string: url) ?? URL(string: "")
        var request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5.0)
        request.httpMethod = "GET"
        request.addValue("cache-control", forHTTPHeaderField: "no-cache")
        request.addValue("accept", forHTTPHeaderField: "*/*")
        request.httpShouldHandleCookies = true
        request.timeoutInterval = 5
        let sessionTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            completionHandler(["data":data ?? Data(), "content-type": (response?.mimeType ?? ""), "url" :response?.url?.absoluteString ?? "", "status_code": "200", "error": ""])
        }
        sessionTask.resume()
    }
}
