//
//  Decoder.swift
//  lib0-swift
//
//  Created by yuki on 2023/03/09.
//

import Foundation

enum Lib0DecoderError: String, LocalizedError {
    case integerOverflow = "Integer overflow."
    case unexpectedEndOfArray = "Unexpected End of Array."
    case unkownStringEncodingType = "Unkown string encoding type."
    case useOfBigintType = "Swift has no bigint type."
    case typeMissmatch = "Type missmatch."
}

/// A Decoder handles the decoding of an Data
final class Lib0Decoder {
    
    /// Decoding target.
    let data: Data
    
    // Current decoding position.
    private var position: Int = 0
    
    init(data: Data) { self.data = data }
    
    var hasContent: Bool {
        return self.position != data.count
    }
    
    func readData(count: Int) -> Data {
        defer { position += count }
        return data[position..<position+count]
    }
    func readVarData() throws -> Data {
        let count = try Int(self.readUInt())
        return self.readData(count: count)
    }
    func readTailAsData() -> Data {
        return self.readData(count: data.count - position)
    }
    
    
    func skip8() {
        self.position += 1
    }
    func readUInt8() -> UInt8 {
        defer { self.position += 1 }
        return self.data[self.position]
    }
    func readUInt16() -> UInt16 {
        defer { self.position += 2 }
        let t1 = (UInt16(self.data[self.position + 0]) << UInt16(8*0))
        let t2 = (UInt16(self.data[self.position + 1]) << UInt16(8*1))
        
        return t1 + t2
    }
    func readUInt32() -> UInt32 {
        defer { self.position += 4 }
        let t1 = (UInt32(self.data[self.position + 0]) << UInt32(8*0))
        let t2 = (UInt32(self.data[self.position + 1]) << UInt32(8*1))
        let t3 = (UInt32(self.data[self.position + 2]) << UInt32(8*2))
        let t4 = (UInt32(self.data[self.position + 3]) << UInt32(8*3))
        
        return t1 + t2 + t3 + t4
    }
    func readUInt64() -> UInt64 {
        defer { self.position += 8 }
        let t1 = (UInt64(self.data[self.position + 0]) << UInt64(8*0))
        let t2 = (UInt64(self.data[self.position + 1]) << UInt64(8*1))
        let t3 = (UInt64(self.data[self.position + 2]) << UInt64(8*2))
        let t4 = (UInt64(self.data[self.position + 3]) << UInt64(8*3))
        let t5 = (UInt64(self.data[self.position + 4]) << UInt64(8*4))
        let t6 = (UInt64(self.data[self.position + 5]) << UInt64(8*5))
        let t7 = (UInt64(self.data[self.position + 6]) << UInt64(8*6))
        let t8 = (UInt64(self.data[self.position + 7]) << UInt64(8*7))
        
        return t1 + t2 + t3 + t4 + t5 + t6 + t7 + t8
    }
    
    func peekUInt8() -> UInt8 {
        return self.data[self.position]
    }
    func peekUInt16() -> UInt16 {
        return UInt16(self.data[self.position]) +
        UInt16(self.data[self.position + 1]) << 8
    }
    func peekUInt32() -> UInt32 {
        return UInt32(self.data[self.position]) +
        UInt32(self.data[self.position + 1]) << 8 +
        UInt32(self.data[self.position + 2]) << 16 +
        UInt32(self.data[self.position + 3]) << 24
    }

    func readUInt() throws -> UInt {
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

    func readInt() throws -> Int {
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
    func peekUInt() throws -> UInt {
        let pos = self.position
        let s = try self.readUInt()
        self.position = pos
        return s
    }
    
    func readString() throws -> String {
        let data = try self.readVarData()
        guard let string = String(data: data, encoding: .utf8) else {
            throw Lib0DecoderError.unkownStringEncodingType
        }
        return string
    }

    func readFloat() -> Float {
        let bigEndianValue = readData(count: 4).reversed().withUnsafeBytes{ ptr in
            ptr.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee }
        }
        return Float(bitPattern: bigEndianValue)
    }
    
    func readDouble() -> Double {
        let bigEndianValue = readData(count: 8).reversed().withUnsafeBytes{ ptr in
            ptr.baseAddress!.withMemoryRebound(to: UInt64.self, capacity: 1) { $0.pointee }
        }
        
        return Double(bitPattern: bigEndianValue)
    }
        
    func readAny() throws -> Any {
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
