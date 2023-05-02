//
//  File.swift
//  
//
//  Created by yuki on 2023/05/02.
//

import Foundation

public typealias LZVariadicCodable = LZVariadicEncodable & LZVariadicDecodable

public struct LZAnyVariadicCodable: LZVariadicCodable {
    public let value: Any?
    
    public init(_ value: Any? = nil) {
        self.value = value
    }
    
    public func writeVariadic(into encoder: LZEncoder) {
        encoder.writeAny(value)
    }
    
    public init(fromVariadic decoder: LZDecoder) throws {
        self.value = try decoder.readAny()
    }
}
