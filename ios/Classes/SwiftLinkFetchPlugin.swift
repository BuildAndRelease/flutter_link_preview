import Flutter
import UIKit
import Photos

public class SwiftLinkFetchPlugin: NSObject, FlutterPlugin, UIAlertViewDelegate {
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
            let url = URL(string: url)
            let request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 15.0)
            NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue()) { (response, data, error) in
                var statusCode = error == nil ? "200" : "201"
                if response is HTTPURLResponse {
                    statusCode = "\((response as! HTTPURLResponse).statusCode)"
                }
                result(["data":data ?? Data(), "content-type": (response?.mimeType ?? ""), "url" :response?.url?.absoluteString ?? "", "status_code": statusCode, "error":(error?.localizedDescription ?? "")])
            }
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
//    public func linkFetch(url : String)  {
//        let url = URL(string: url)
//        let request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 15.0)
//        NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue()) { (response, data, error) in
////            response?.
//            response?.mimeType
//            print(response)
//            print(data)
//            print(error)
//        }
//    }
}
