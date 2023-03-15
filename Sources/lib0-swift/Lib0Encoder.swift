//
//  Lib0Encoder.swift
//  lib0-swift
//
//  Created by yuki on 2023/03/09.
//

import Foundation

public final class Lib0Encoder {
    private var buffers: [Data] = []
    private var currentBuffer = Data(repeating: 0, count: 100)
    private var currentBufferPosition = 0
    
    public init() {}

    public var count: Int {
        self.currentBufferPosition + self.buffers.lazy.map{ $0.count }.reduce(0, +)
    }

    public var data: Data {
        var data = Data()
        data.reserveCapacity(count)
        for buffer in buffers { data.append(buffer) }
        data.append(self.currentBuffer[..<self.currentBufferPosition])
        return data
    }

    public func reserveCapacity(_ minimumCapacity: Int) {
        let bufferSize = self.currentBuffer.count
        if bufferSize - self.currentBufferPosition < minimumCapacity {
            self.buffers.append(
                self.currentBuffer[..<self.currentBufferPosition]
            )
            self.currentBuffer = Data(repeating: 0, count: max(bufferSize, minimumCapacity) * 2)
            self.currentBufferPosition = 0
        }
    }

    public func writeUInt8(_ value: UInt8) {
        let bufferSize = self.currentBuffer.count
        if self.currentBufferPosition == bufferSize {
            self.buffers.append(self.currentBuffer)
            self.currentBuffer = Data(repeating: 0, count: bufferSize * 2)
            self.currentBufferPosition = 0
        }
        self.currentBuffer[self.currentBufferPosition] = value
        self.currentBufferPosition += 1
    }

    public func writeUInt(_ value: UInt) {
        var value = value
        while (value > 0b0111_1111) {
            self.writeUInt8(0b1000_0000 | UInt8(0b0111_1111 & value))
            value >>= 7
        }
        self.writeUInt8(UInt8(0b0111_1111 & value))
    }
    
    public func writeInt(_ value: Int) {
        var value = value
        let isNegative = value < 0
        if (isNegative) { value = -value }
        
        self.writeUInt8(
            UInt8(value > 0b0011_1111 ? 0b1000_0000 : 0) | // whether to continue reading (8th bit)
            UInt8(isNegative ? 0b0100_0000 : 0) |          // whether is negative (7th bit)
            UInt8(0b0011_1111 & value)                     // number (bottom 6bits)
        )
        value >>= 6
        while (value > 0) {
            self.writeUInt8(
                UInt8(value > 0b0111_1111 ? 0b1000_0000 : 0) | // whether to continue reading (8th bit)
                UInt8(0b0111_1111 & value) // number (bottom 7bits)
            )
            value >>= 7
        }
    }

    public func writeString(_ value: String) {
        self.writeData(value.data(using: .utf8)!)
    }

    public func writeData(_ data: Data) {
        self.writeUInt(UInt(data.count))
        self.writeOpaqueSizeData(data)
    }
    public func writeOpaqueSizeData(_ data: Data) {
        let bufferLen = self.currentBuffer.count
        let cpos = self.currentBufferPosition
        let leftCopyLen = min(bufferLen - cpos, data.count)
        let rightCopyLen = data.count - leftCopyLen
        
        let subdata = data[0..<leftCopyLen]
        self.currentBuffer[cpos..<cpos+subdata.count] = subdata
        self.currentBufferPosition += leftCopyLen

        if rightCopyLen > 0 {
            self.buffers.append(self.currentBuffer)
            self.currentBuffer = Data(repeating: 0, count: max(bufferLen * 2, rightCopyLen))
            let subdata = data[leftCopyLen...]
            self.currentBuffer[0..<subdata.count] = subdata
            self.currentBufferPosition = rightCopyLen
        }
    }
    
    public func writeFloat(_ value: Float) {
        let value = value.bitPattern
        for i in (0..<4).reversed() {
            self.writeUInt8(UInt8((value >> (8 * i)) & 0b1111_1111))
        }
    }
    public func writeDouble(_ value: Double) {
        let value = value.bitPattern
        for i in (0..<8).reversed() {
            self.writeUInt8(UInt8((value >> (8 * i)) & 0b1111_1111))
        }
    }

    public func writeAny(_ data: Any) {
        switch (data) {
        case let data as String:
            self.writeUInt8(119)
            self.writeString(data)
        case let data as Int:
            self.writeUInt8(125)
            self.writeInt(data)
        case let data as Float:
            self.writeUInt8(124)
            self.writeFloat(data)
        case let data as Double:
            self.writeUInt8(123)
            self.writeDouble(data)
        case let data as [String: Any]:
            self.writeUInt8(118)
            self.writeUInt(UInt(data.count))
            for (key, value) in data {
                self.writeString(key)
                self.writeAny(value)
            }
        case let data as Data:
            self.writeUInt8(116)
            self.writeData(data)
            
        case let data as [Any]:
            self.writeUInt8(117)
            self.writeUInt(UInt(data.count))
            for element in data {
                self.writeAny(element)
            }
        case let data as Bool:
            self.writeUInt8(data ? 120 : 121)
        default:
            self.writeUInt8(127)
        }
    }
}
