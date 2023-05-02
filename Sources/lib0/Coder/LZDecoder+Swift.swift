//
//  File.swift
//  
//
//  Created by yuki on 2023/05/01.
//

import Foundation

public protocol LZDecodable {
    init(from decoder: LZDecoder) throws
}
public protocol LZVariadicDecodable {
    init(fromVariadic decoder: LZDecoder) throws
}

extension Int: LZDecodable, LZVariadicDecodable {
    public init(from decoder: LZDecoder) throws { self = try decoder.readInt() }
    
    public init(fromVariadic decoder: LZDecoder) throws {
        let refID = decoder.readUInt8()
        assert(refID == 125)
        self = try decoder.readInt()
    }
}
extension UInt: LZDecodable, LZVariadicDecodable {
    public init(from decoder: LZDecoder) throws { self = try decoder.readUInt() }
    
    public init(fromVariadic decoder: LZDecoder) throws {
        let refID = decoder.readUInt8()
        assert(refID == 125)
        self = try UInt(decoder.readInt())
    }
}
extension UInt8: LZDecodable {
    public init(from decoder: LZDecoder) throws { self = decoder.readUInt8() }
}
extension String: LZDecodable, LZVariadicDecodable {
    public init(from decoder: LZDecoder) throws { self = try decoder.readString() }
    
    public init(fromVariadic decoder: LZDecoder) throws {
        let refID = decoder.readUInt8()
        assert(refID == 119)
        self = try decoder.readString()
    }
}
extension Data: LZDecodable, LZVariadicDecodable {
    public init(from decoder: LZDecoder) throws { self = try decoder.readData() }
    
    public init(fromVariadic decoder: LZDecoder) throws {
        let refID = decoder.readUInt8()
        assert(refID == 116)
        self = try decoder.readData()
    }
}
extension Float: LZDecodable, LZVariadicDecodable {
    public init(from decoder: LZDecoder) throws { self = decoder.readFloat() }
    
    public init(fromVariadic decoder: LZDecoder) throws {
        let refID = decoder.readUInt8()
        assert(refID == 124)
        self = decoder.readFloat()
    }
}
extension Double: LZDecodable, LZVariadicDecodable {
    public init(from decoder: LZDecoder) throws { self = decoder.readDouble() }
    
    public init(fromVariadic decoder: LZDecoder) throws {
        let refID = decoder.readUInt8()
        assert(refID == 123)
        self = decoder.readDouble()
    }
}
extension Bool: LZVariadicDecodable {
    public init(fromVariadic decoder: LZDecoder) throws {
        let refID = decoder.readUInt8()
        assert(refID == 120 || refID == 121)
        self = refID == 120
    }
}
extension Optional: LZVariadicDecodable where Wrapped: LZVariadicDecodable {
    public init(fromVariadic decoder: LZDecoder) throws {
        let refID = decoder.readUInt8()
        if refID == 126 { self = .none; return }
        self = .some(try Wrapped(fromVariadic: decoder))
    }
}
extension Array: LZVariadicDecodable where Element: LZVariadicDecodable {
    public init(fromVariadic decoder: LZDecoder) throws {
        let refID = decoder.readUInt8()
        assert(refID == 117)
        self.init()
        
        let count = Int(try decoder.readUInt())
        self.reserveCapacity(count)
        for _ in 0..<count {
            let refID = decoder.readUInt8()
            self.append(try Element(fromVariadic: decoder))
        }
    }
}
extension Dictionary: LZVariadicDecodable where Key == String, Value: LZVariadicDecodable {
    public init(fromVariadic decoder: LZDecoder) throws {
        self.init()
        let refID = decoder.readUInt8()
        assert(refID == 118)
        let count = Int(try decoder.readUInt())
        var dict: [String: Any?] = [:]
        dict.reserveCapacity(count)
        for _ in 0..<count {
            dict[try decoder.readString()] = try Value(fromVariadic: decoder)
        }
    }
}

extension LZDecoder {
    public func readVariadic<T: LZVariadicDecodable>(_: T.Type) throws -> T {
        return try T(fromVariadic: self)
    }
    
    public func readRawRepresentable<T: RawRepresentable>() throws -> T where T.RawValue: LZDecodable {
        guard let value = T(rawValue: try T.RawValue(from: self)) else {
            throw LZDecoderError.unexpectedCase
        }
        return value
    }
}
