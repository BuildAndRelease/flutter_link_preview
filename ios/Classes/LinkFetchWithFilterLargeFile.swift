//
//  LinkFetch.swift
//  flutter_link_preview
//
//  Created by johnson_zhong on 2020/12/25.
//

import Foundation

class LinkFetchWithFilterLargeFile : NSObject, URLSessionDataDelegate{
    
    var completionHandler : ((Dictionary<String, Any>) -> Void)?
    var url : String?
    var resultData = Data()
    var response : URLResponse?
    
    init(url : String, completionHandler : @escaping (Dictionary<String, Any>) -> Void) {
        self.url = url
        self.completionHandler = completionHandler
    }
    
    deinit {
        resultData.removeAll(keepingCapacity: false)
        response = nil
    }
    
    func fetch() {
        guard let link = URL(string: self.url ?? "") else {
            self.completionHandler?(Dictionary<String, Any>())
            return
        }
        var request = URLRequest(url: link, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5.0)
        request.httpMethod = "GET"
        request.addValue("no-cache", forHTTPHeaderField: "cache-control")
        request.addValue("*/*", forHTTPHeaderField: "accept")
        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.125 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.httpShouldHandleCookies = true
        request.timeoutInterval = 5
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        session.dataTask(with: request).resume()
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response
        let (info, canContinue) = canFetchContinue(data: nil, response: response, error: nil)
        if (!canContinue) {
            completionHandler(.cancel)
            self.completionHandler?(info)
        }else {
            completionHandler(.allow)
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        switch dataTask.state {
        case .canceling:
            resultData.append(data)
            self.completionHandler?(["data":Data(), "content-type": response?.mimeType ?? "", "url" :dataTask.currentRequest?.url?.absoluteString ?? "", "status_code": "201", "error": "reuqest canceling"])
        case .suspended:
            resultData.append(data)
            self.completionHandler?(["data":Data(), "content-type": response?.mimeType ?? "", "url" :dataTask.currentRequest?.url?.absoluteString ?? "", "status_code": "201", "error": "reuqest suspended"])
        case .running:
            resultData.append(data)
        case .completed:
            resultData.append(data)
        default:
            break
        }
        if resultData.count > 30 * 1024 * 1024 {
            resultData.removeAll(keepingCapacity: false)
            dataTask.cancel()
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            self.completionHandler?(["data":Data(), "content-type": task.response?.mimeType ?? "", "url" :task.response?.url?.absoluteString ?? "", "status_code": "201", "error": error?.localizedDescription ?? ""])
        }else {
            self.completionHandler?(["data":resultData, "content-type": task.response?.mimeType ?? "", "url" :task.response?.url?.absoluteString ?? "", "status_code": "200", "error": ""])
        }
        session.finishTasksAndInvalidate()
    }
    
    func canFetchContinue(data : Data?, response : URLResponse?, error : Error?) -> ((Dictionary<String, Any>), Bool) {
        if let response = response, response is HTTPURLResponse{
            let allHeader = (response as! HTTPURLResponse).allHeaderFields
            let statusCode = "\((response as! HTTPURLResponse).statusCode)"
            var length = "0"
            var mimeType = ""
            for header in allHeader {
                if header.key is String {
                    switch (header.key as! String).lowercased() {
                    case "content-length":
                        length = String(describing: header.value)
                        break
                    case "content-type":
                        mimeType = String(describing: header.value)
                        break
                    default:
                        break
                    }
                }
            }
            if statusCode != "200" {
                return(["data":Data(), "content-type": mimeType, "url" :response.url?.absoluteString ?? "", "status_code": statusCode, "error": ""], false)
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
