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
        guard let link = URL(string: self.url?.urlEncoded() ?? "") else {
            self.completionHandler?(Dictionary<AnyHashable, Any>())
            return
        }
        var request = URLRequest(url: link, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5.0)
        request.httpMethod = "GET"
        request.addValue("no-cache", forHTTPHeaderField: "cache-control")
        request.addValue("*/*", forHTTPHeaderField: "accept")
        if let hostString = link.host, (hostString.contains("weibo.com") || hostString.contains("weibo.cn")) {
            request.addValue("YF-Page-G0=02467fca7cf40a590c28b8459d93fb95|1596707497|1596707497; SUB=_2AkMod12Af8NxqwJRmf8WxGjna49_ygnEieKeK6xbJRMxHRl-yT9kqlcftRB6A_dzb7xq29tqJiOUtDsy806R_ZoEGgwS; SUBP=0033WrSXqPxfM72-Ws9jqgMF55529P9D9W59fYdi4BXCzHNAH7GabuIJ", forHTTPHeaderField: "Cookie")
            request.addValue("Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        }else {
            request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/84.0.4147.125 Safari/537.36", forHTTPHeaderField: "User-Agent")
        }
        request.httpShouldHandleCookies = true
        request.timeoutInterval = 5
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        session.dataTask(with: request).resume()
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
