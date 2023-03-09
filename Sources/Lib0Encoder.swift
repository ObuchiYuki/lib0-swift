//
//  Lib0Encoder.swift
//  lib0-swift
//
//  Created by yuki on 2023/03/09.
//

import Foundation

final class Lib0Encoder {
    private var buffers: [Data] = []
    private var currentBuffer = Data(repeating: 0, count: 100)
    private var currentBufferPosition = 0

    /** The current length of the encoded data. */
    var length: Int {
        self.currentBufferPosition + self.buffers.lazy.map{ $0.count }.reduce(0, +)
    }

    /** Transform to Uint8Array. */
    var data: Data {
        var data = Data()
        data.reserveCapacity(length)
        for buffer in buffers { data.append(buffer) }
        data.append(self.currentBuffer[..<self.currentBufferPosition])
        return data
    }

    /**
     * Verify that it is possible to write `len` bytes wtihout checking. If
     * necessary, a new Buffer with the required length is attached.
     */
    func reserveCapacity(_ minimumCapacity: Int) {
        let bufferSize = self.currentBuffer.count
        if bufferSize - self.currentBufferPosition < minimumCapacity {
            self.buffers.append(
                self.currentBuffer[..<self.currentBufferPosition]
            )
            self.currentBuffer = Data(repeating: 0, count: max(bufferSize, minimumCapacity) * 2)
            self.currentBufferPosition = 0
        }
    }

    func writeUInt8(_ value: UInt8) {
        let bufferSize = self.currentBuffer.count
        if self.currentBufferPosition == bufferSize {
            self.buffers.append(self.currentBuffer)
            self.currentBuffer = Data(repeating: 0, count: bufferSize * 2)
            self.currentBufferPosition = 0
        }
        self.currentBuffer[self.currentBufferPosition] = value
        self.currentBufferPosition += 1
    }
    func setUInt8(_ value: UInt8, at position: Int) {
        assert(self.length < position)
        
        var position = position
        var foundBufferIndex = -1
        for (i, buffer) in buffers.enumerated() {
            if (position < buffer.count) {
                foundBufferIndex = i
            } else {
                position -= buffer.count
            }
        }
        if foundBufferIndex == -1 {
            self.currentBuffer[position] = value
        } else {
            self.buffers[foundBufferIndex][position] = value
        }
    }

    func writeUInt16(_ value: UInt16) {
        self.writeUInt8(UInt8(value >> 0 & 0b1111_1111))
        self.writeUInt8(UInt8(value >> 8 & 0b1111_1111))
    }
    func setUint16(_ value: UInt16, at position: Int) {
        self.setUInt8(UInt8((value >> 0) & 0b1111_1111), at: position + 0)
        self.setUInt8(UInt8((value >> 8) & 0b1111_1111), at: position + 1)
    }

    func writeUInt32(_ value: UInt32) {
        var value = value
        for _ in 0..<4 {
            self.writeUInt8(UInt8(value & 0b1111_1111))
            value >>= 8
        }
    }
    func setUInt32(_ value: UInt32, at position: Int) {
        var value = value
        for i in 0..<4 {
            self.setUInt8(UInt8(value & 0b1111_1111), at: position + i)
            value >>= 8
        }
    }
    
    func writeUInt64(_ value: UInt64) {
        var value = value
        for _ in 0..<8 {
            self.writeUInt8(UInt8(value & 0b1111_1111))
            value >>= 8
        }
    }
    func setUInt64(_ value: UInt64, at position: Int) {
        var value = value
        for i in 0..<8 {
            self.setUInt8(UInt8(value & 0b1111_1111), at: position + i)
            value >>= 8
        }
    }

    func writeUInt(_ value: UInt) {
        var value = value
        while (value > 0b0111_1111) {
            self.writeUInt8(0b1000_0000 | UInt8(0b0111_1111 & value))
            value >>= 7
        }
        self.writeUInt8(UInt8(0b0111_1111 & value))
    }
    func writeInt(_ value: Int) {
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

    func writeVarString(_ value: String) {
        //                       never return nil ↓
        self.writeVarData(value.data(using: .utf8)!)
    }

    func writeOpaqueSizeData(_ data: Data) {
        let bufferLen = self.currentBuffer.count
        let cpos = self.currentBufferPosition
        let leftCopyLen = min(bufferLen - cpos, data.count)
        let rightCopyLen = data.count - leftCopyLen
        
        let subdata = data[0..<leftCopyLen]
        self.currentBuffer[cpos..<cpos+subdata.count] = subdata
        self.currentBufferPosition += leftCopyLen

        if rightCopyLen > 0 {
            // Still something to write, write right half..
            // Append new buffer
            self.buffers.append(self.currentBuffer)
            // must have at least size of remaining buffer
            self.currentBuffer = Data(repeating: 0, count: max(bufferLen * 2, rightCopyLen))
            // copy array
            let subdata = data[0..<leftCopyLen]
            self.currentBuffer[0..<subdata.count] = subdata
            self.currentBufferPosition = rightCopyLen
        }
    }

    func writeVarData(_ data: Data) {
        self.writeUInt(UInt(data.count))
        self.writeOpaqueSizeData(data)
    }

    func writeFloat(_ value: Float) {
        var value = value.bitPattern
        for i in (0..<4).reversed() {
            self.writeUInt8(UInt8((value >> (8 * i)) & 0b1111_1111))
        }
    }
    func writeDouble(_ value: Double) {
        var value = value.bitPattern
        for i in (0..<8).reversed() {
            self.writeUInt8(UInt8((value >> (8 * i)) & 0b1111_1111))
        }
    }

    func writeAny(_ data: Any) {   
        switch (data) {
        case let data as String:
            self.writeUInt8(119)
            self.writeVarString(data)
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
                self.writeVarString(key)
                self.writeAny(value)
            }
        case let data as Data:
            self.writeUInt8(116)
            self.writeVarData(data)
            
        case let data as [Any]:
            self.writeUInt8(117)
            self.writeUInt(UInt(data.count))
            for element in data {
                self.writeAny(element)
            }
        case let data as Bool:
            self.writeUInt8(data ? 120 : 121)
        default:
            
            // TYPE 126: null
//            self.writeUInt8(126)
//          // TYPE 126: undefined
            self.writeUInt8(127)
        }
    }
}
