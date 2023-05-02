//
//  File.swift
//  
//
//  Created by yuki on 2023/05/01.
//

import Foundation

public protocol LZEncodable {
    func write(into encoder: LZEncoder)
}
public protocol LZVariadicEncodable {
    func writeVariadic(into encoder: LZEncoder)
}

extension NSNull: LZVariadicEncodable {
    public func writeVariadic(into encoder: LZEncoder) {
        encoder.writeUInt8(126)
    }
}
extension Bool: LZVariadicEncodable {
    public func writeVariadic(into encoder: LZEncoder) {
        encoder.writeUInt8(self ? 120 : 121)
    }
}
extension UInt8: LZEncodable {
    public func write(into encoder: LZEncoder) { encoder.writeUInt8(self) }
}
extension Int: LZEncodable, LZVariadicEncodable {
    public func write(into encoder: LZEncoder) { encoder.writeInt(self) }
    public func writeVariadic(into encoder: LZEncoder) {
        encoder.writeUInt8(125)
        encoder.writeInt(self)
    }
}
extension UInt: LZEncodable, LZVariadicEncodable {
    public func write(into encoder: LZEncoder) { encoder.writeUInt(self) }
    
    public func writeVariadic(into encoder: LZEncoder) {
        encoder.writeUInt8(125)
        encoder.writeInt(Int(self))
    }
}
extension String: LZEncodable, LZVariadicEncodable {
    public func write(into encoder: LZEncoder) { encoder.writeString(self) }
    
    public func writeVariadic(into encoder: LZEncoder) {
        encoder.writeUInt8(119)
        encoder.writeString(self)
    }
}
extension Data: LZEncodable, LZVariadicEncodable {
    public func write(into encoder: LZEncoder) { encoder.writeData(self) }
    
    public func writeVariadic(into encoder: LZEncoder) {
        encoder.writeUInt8(116)
        encoder.writeData(self)
    }
}
extension Float: LZEncodable, LZVariadicEncodable {
    public func write(into encoder: LZEncoder) { encoder.writeFloat(self) }
    
    public func writeVariadic(into encoder: LZEncoder) {
        encoder.writeUInt8(124)
        encoder.writeFloat(self)
    }
}
extension Double: LZEncodable, LZVariadicEncodable {
    public func write(into encoder: LZEncoder) { encoder.writeDouble(self) }
    
    public func writeVariadic(into encoder: LZEncoder) {
        encoder.writeUInt8(123)
        encoder.writeDouble(self)
    }
}

extension Optional: LZVariadicEncodable where Wrapped: LZVariadicEncodable {
    public func writeVariadic(into encoder: LZEncoder) {
        switch self {
        case .none: encoder.writeUInt8(126)
        case .some(let value): value.writeVariadic(into: encoder)
        }
    }
}
extension Array: LZVariadicEncodable where Element: LZVariadicEncodable {
    public func writeVariadic(into encoder: LZEncoder) {
        encoder.writeUInt8(117)
        encoder.writeUInt(UInt(self.count))
        for element in self {
            element.writeVariadic(into: encoder)
        }
    }
}
extension Dictionary: LZVariadicEncodable where Key == String, Value: LZVariadicEncodable {
    public func writeVariadic(into encoder: LZEncoder) {
        encoder.writeUInt8(118)
        encoder.writeUInt(UInt(self.count))
        for (key, value) in self {
            encoder.writeString(key)
            value.writeVariadic(into: encoder)
        }
    }
}
extension LZEncoder {
    public func write<T: RawRepresentable>(_ value: T) where T.RawValue: LZEncodable {
        value.rawValue.write(into: self)
    }
    
    public func writeVariadic<T: LZVariadicEncodable>(_ value: T) {
        value.writeVariadic(into: self)
    }
}
