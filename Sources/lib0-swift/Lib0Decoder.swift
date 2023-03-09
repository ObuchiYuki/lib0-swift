//
//  Decoder.swift
//  lib0-swift
//
//  Created by yuki on 2023/03/09.
//

import Foundation

public enum Lib0DecoderError: String, LocalizedError {
    case integerOverflow = "Integer overflow."
    case unexpectedEndOfArray = "Unexpected End of Array."
    case unkownStringEncodingType = "Unkown string encoding type."
    case useOfBigintType = "Swift has no bigint type."
    case typeMissmatch = "Type missmatch."
}

public final class Lib0Decoder {

    private let data: Data
    private var position: Int = 0
    
    public init(data: Data) { self.data = data }
    
    public var hasContent: Bool {
        return self.position != data.count
    }
    
    public func readData(count: Int) -> Data {
        defer { position += count }
        return data[position..<position+count]
    }
    public func readVarData() throws -> Data {
        let count = try Int(self.readUInt())
        return self.readData(count: count)
    }
    public func readTailAsData() -> Data {
        return self.readData(count: data.count - position)
    }
    
    public func skip8() {
        self.position += 1
    }
    public func readUInt8() -> UInt8 {
        defer { self.position += 1 }
        return self.data[self.position]
    }
    public func readUInt16() -> UInt16 {
        defer { self.position += 2 }
        var value: UInt16 = 0
        for i in 0..<2 { value += UInt16(self.data[self.position + i]) << UInt16(8*i) }
        return value
    }
    public func readUInt32() -> UInt32 {
        defer { self.position += 4 }
        var value: UInt32 = 0
        for i in 0..<4 { value += UInt32(self.data[self.position + i]) << UInt32(8*i) }
        return value
    }
    public func readUInt64() -> UInt64 {
        defer { self.position += 8 }
        var value: UInt64 = 0
        for i in 0..<8 { value += UInt64(self.data[self.position + i]) << UInt64(8*i) }
        return value
    }
    
    public func peekUInt8() -> UInt8 {
        return self.data[self.position]
    }
    public func peekUInt16() -> UInt16 {
        defer { position -= 2 }
        return self.readUInt16()
    }
    public func peekUInt32() -> UInt32 {
        defer { position -= 4 }
        return self.readUInt32()
    }
    public func peekUInt64() -> UInt64 {
        defer { position -= 8 }
        return self.readUInt64()
    }

    public func readUInt() throws -> UInt {
        var num: UInt = 0
        var mult: UInt = 1
        let len = self.data.count
        while self.position < len {
            let r = UInt(self.data[self.position])
            self.position += 1
            
            let (pnum, overflow) = num.addingReportingOverflow((r & 0b0111_1111) * mult)
            if overflow {
                throw Lib0DecoderError.integerOverflow
            }
            num = pnum
            mult *= 128
            if (r < 0b1000_0000) { return num }
        }
        throw Lib0DecoderError.unexpectedEndOfArray
    }
    public func peekUInt() throws -> UInt {
        let pos = self.position
        let s = try self.readUInt()
        self.position = pos
        return s
    }

    public func readInt() throws -> Int {
        var r = Int(self.data[self.position])
        self.position += 1
        var num = r & 0b0011_1111
        var mult = 64
        let sign = (r & 0b0100_0000) > 0 ? -1 : 1
        if (r & 0b1000_0000) == 0 { return sign * num }
        let len = self.data.count
        
        while self.position < len {
            r = Int(self.data[self.position])
            self.position += 1
            let (pnum, overflow) = num.addingReportingOverflow((r & 0b0111_1111) * mult)
            if overflow { throw Lib0DecoderError.integerOverflow }
            num = pnum
            mult *= 128
            if (r < 0b1000_0000) { return sign * num }
        }
        throw Lib0DecoderError.unexpectedEndOfArray
    }
    public func peekInt() throws -> Int {
        let pos = self.position
        let s = try self.readInt()
        self.position = pos
        return s
    }
    
    public func readString() throws -> String {
        let data = try self.readVarData()
        guard let string = String(data: data, encoding: .utf8) else {
            throw Lib0DecoderError.unkownStringEncodingType
        }
        return string
    }

    public func readFloat() -> Float {
        let bigEndianValue = readData(count: 4).reversed().withUnsafeBytes{ ptr in
            ptr.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee }
        }
        return Float(bitPattern: bigEndianValue)
    }
    
    public func readDouble() -> Double {
        let bigEndianValue = readData(count: 8).reversed().withUnsafeBytes{ ptr in
            ptr.baseAddress!.withMemoryRebound(to: UInt64.self, capacity: 1) { $0.pointee }
        }
        
        return Double(bitPattern: bigEndianValue)
    }
        
    public func readAny() throws -> Any {
        let type = self.readUInt8()
        
        switch type {
        case 125: return try self.readInt()
        case 124: return self.readFloat()
        case 123: return self.readDouble()
        case 122: throw Lib0DecoderError.useOfBigintType
        case 121: return false
        case 120: return true
        case 119: return try readString()
        case 118:
            let count = try self.readUInt()
            var dictionary: [String: Any] = [:]
            for _ in 0..<count {
                let key = try self.readString()
                dictionary[key] = try self.readAny()
            }
            return dictionary
        case 117:
            let length = Int(try self.readUInt())
            var array: [Any] = []
            array.reserveCapacity(length)
            for _ in 0..<length {
                array.append(try self.readAny())
            }
            return array
        default: return Optional<Void>.none as Any
        }
    }
}
