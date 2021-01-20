//
//  LinkHeadFetch.swift
//  flutter_link_preview
//
//  Created by johnson_zhong on 2020/12/25.
//

import Foundation

class LinkFetchHeader : NSObject, URLSessionDataDelegate{
    
    var completionHandler : ((Dictionary<AnyHashable, Any>) -> Void)?
    var url : String?
    
    init(url : String, completionHandler : @escaping (Dictionary<AnyHashable, Any>) -> Void) {
        self.url = url
        self.completionHandler = completionHandler
    }
    
    deinit {
        print("deinit")
    }

    func fetch() {
        if let link = URL(string: self.url ?? "") {
            var request = URLRequest(url: link, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5.0)
            request.httpMethod = "GET"
            request.addValue("no-cache", forHTTPHeaderField: "cache-control")
            request.addValue("*/*", forHTTPHeaderField: "accept")
            request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.125 Safari/537.36", forHTTPHeaderField: "User-Agent")
            request.httpShouldHandleCookies = true
            request.timeoutInterval = 5
            
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
            session.dataTask(with: request).resume()
        }else {
            self.completionHandler?(Dictionary<AnyHashable, Any>())
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.cancel)
        if let httpUrlReponse = response as? HTTPURLResponse {
            self.completionHandler?(httpUrlReponse.allHeaderFields)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        session.finishTasksAndInvalidate()
    }
}
