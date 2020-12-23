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
//        let url = "http://world.people.com.cn/n1/2020/0805/c1002-31811808.html"
//        let url = "https://mp.weixin.qq.com/s/qj7gkU-Pbdcdn3zO6ZQxqg"
//        let url = "https://fb-cdn.fanbook.mobi/fanbook/download/apk/Fanbook_1.3.1_27.apk"
        switch (call.method) {
        case "linkFetch":
            fetchLinkInfo(url: url) { (dictionary) in
                result(dictionary)
            }
            break
        case "linkFetchWithFilterLargeFile":
            linkFetchWithFilterLargeFile(url: url) { (dictionary) in
                result(dictionary)
            }
            break
        case "linkFetchHead":
            fetchLinkHead(url: url, completionHandler: { (dictionary) in
                result(dictionary)
            })
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func fetchLinkHead(url : String, completionHandler : @escaping (Dictionary<String, Any>) -> Void) {
        let url = URL(string: url) ?? URL(string: "")
        var request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5.0)
        request.httpMethod = "HEAD"
        request.addValue("cache-control", forHTTPHeaderField: "no-cache")
        request.addValue("accept", forHTTPHeaderField: "*/*")
        request.httpShouldHandleCookies = true
        request.timeoutInterval = 5
        let sessionTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            completionHandler(["data":data ?? Data(), "content-type": (response?.mimeType ?? ""), "url" :response?.url?.absoluteString ?? "", "status_code": "200", "error": ""])
        }
        sessionTask.resume()
        
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
    
    func linkFetchWithFilterLargeFile(url : String, completionHandler : @escaping (Dictionary<String, Any>) -> Void) {
        let url = URL(string: url) ?? URL(string: "")
        var request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5.0)
        request.httpMethod = "HEAD"
        request.addValue("cache-control", forHTTPHeaderField: "no-cache")
        request.addValue("accept", forHTTPHeaderField: "*/*")
        request.httpShouldHandleCookies = true
        request.timeoutInterval = 5
        weak var weakSelf =  self
        let sessionTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error == nil, response != nil {
                let (info, canContinue) = weakSelf?.canFetchContinue(data: data, response: response, error: error) ?? (Dictionary(), false)
                if (!canContinue) {
                    completionHandler(info)
                    return
                }
            }
            request.httpMethod = "GET"
            let sessionGetTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
                let (info, canContinue) = weakSelf?.canFetchContinue(data: data, response: response, error: error) ?? (Dictionary(), false)
                if (!canContinue) {
                    completionHandler(info)
                    return
                }
                completionHandler(["data":data ?? Data(), "content-type": (response?.mimeType ?? ""), "url" :response?.url?.absoluteString ?? "", "status_code": "200", "error": ""])
            }
            sessionGetTask.resume()
        }
        sessionTask.resume()
    }
    
    func canFetchContinue(data : Data?, response : URLResponse?, error : Error?) -> ((Dictionary<String, Any>), Bool) {
        let statusCode = error == nil ? "200" : "201"
        if let response = response, response is HTTPURLResponse{
            let allHeader = (response as! HTTPURLResponse).allHeaderFields
            var length = "0"
            var mimeType = ""
            for header in allHeader {
                if header.key is String {
                    switch (header.key as! String) {
                    case "Content-Length":
                        length = String(describing: header.value)
                        break
                    case "Content-Type":
                        mimeType = String(describing: header.value)
                        break
                    default:
                        break
                    }
                }
            }
            if Int(length) ?? 0 >= 50 * 1024 * 1024 {
                return(["data":Data(), "content-type": mimeType, "url" :response.url?.absoluteString ?? "", "status_code": statusCode, "error": ""], false)
            }
            if !mimeType.contains("text/html"), !mimeType.contains("text/asp") {
                return(["data":Data(), "content-type": mimeType, "url" :response.url?.absoluteString ?? "", "status_code": statusCode, "error":(error?.localizedDescription ?? "")], false)
            }
        }
        return (Dictionary(), true)
    }
}
