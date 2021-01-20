//
//  StringExtension.swift
//  flutter_link_preview
//
//  Created by johnson_zhong on 2021/1/20.
//

import Foundation

extension String {
     
    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters:
            .urlQueryAllowed)
        return encodeUrlString ?? ""
    }
     
    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }
}
