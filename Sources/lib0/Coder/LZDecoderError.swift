//
//  File.swift
//  
//
//  Created by yuki on 2023/03/25.
//

import Foundation

public struct LZDecoderError: LocalizedError {
    public var errorDescription: String
    
    init(_ message: String) {
        self.errorDescription = message
    }
    
    static let integerOverflow = LZDecoderError("Integer overflow.")
    static let unexpectedEndOfArray = LZDecoderError("Unexpected End of Array.")
    static let unkownStringEncodingType = LZDecoderError("Unkown string encoding type.")
    static let useOfBigintType = LZDecoderError("Swift has no bigint type.")
    static let typeMissmatch = LZDecoderError("Type missmatch.")
    static let unexpectedCase = LZDecoderError("Unexpected case.")
}
