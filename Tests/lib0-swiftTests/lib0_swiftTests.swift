import XCTest
@testable import lib0_swift

final class lib0_swiftTests: XCTestCase {
    func testFixedInteger() {
        // UInt8
        for _ in 0..<100 {
            let value = UInt8.random(in: UInt8.min...UInt8.max)
            let encoder = Lib0Encoder()
            encoder.writeUInt8(value)
            
            let decoder = Lib0Decoder(data: encoder.data)
            XCTAssertEqual(decoder.readUInt8(), value)
        }
        
        // UInt16
        for _ in 0..<100 {
            let value = UInt16.random(in: UInt16.min...UInt16.max)
            let encoder = Lib0Encoder()
            encoder.writeUInt16(value)
            
            let decoder = Lib0Decoder(data: encoder.data)
            XCTAssertEqual(decoder.readUInt16(), value)
        }
        
        // UInt32
        for _ in 0..<100 {
            let value = UInt32.random(in: UInt32.min...UInt32.max)
            let encoder = Lib0Encoder()
            encoder.writeUInt32(value)
            
            let decoder = Lib0Decoder(data: encoder.data)
            XCTAssertEqual(decoder.readUInt32(), value)
        }
        
        // UInt64
        for _ in 0..<100 {
            let value = UInt64.random(in: UInt64.min...UInt64.max)
            let encoder = Lib0Encoder()
            encoder.writeUInt64(value)
            
            let decoder = Lib0Decoder(data: encoder.data)
            XCTAssertEqual(decoder.readUInt64(), value)
        }
    }
    
    func testVariadicInteger() throws {
        // UInt
        for _ in 0..<1000 {
            let value = UInt.random(in: UInt.min...UInt.max/64)
            let encoder = Lib0Encoder()
            encoder.writeUInt(value)
            
            let decoder = Lib0Decoder(data: encoder.data)
            XCTAssertEqual(try decoder.readUInt(), value)
        }
        
        // Int
        for _ in 0..<1000 {
            let value = Int.random(in: Int.min/64...Int.max/64)
            let encoder = Lib0Encoder()
            encoder.writeInt(value)
            
            let decoder = Lib0Decoder(data: encoder.data)
            XCTAssertEqual(try decoder.readInt(), value)
        }
    }
    
    func testFloatingPoint() throws {
        // Float
        for _ in 0..<100 {
            let value = Float.random(in: -1e+38...1e+38)
            let encoder = Lib0Encoder()
            encoder.writeFloat(value)
            
            let decoder = Lib0Decoder(data: encoder.data)
            XCTAssertEqual(decoder.readFloat(), value)
        }
        
        // Double
        for _ in 0..<100 {
            let value = Double.random(in: -1e+38...1e+38)
            let encoder = Lib0Encoder()
            encoder.writeDouble(value)
            
            let decoder = Lib0Decoder(data: encoder.data)
            XCTAssertEqual(decoder.readDouble(), value)
        }
        
        // Double
    }
    
    func testString() throws {
        for _ in 0..<100 {
            let value = makeRandomString(200)
            let encoder = Lib0Encoder()
            encoder.writeString(value)
            
            let decoder = Lib0Decoder(data: encoder.data)
            XCTAssertEqual(try decoder.readString(), value)
        }
    }
    
    func testAny() throws {
        // [String: Int]
        for _ in 0..<100 {
            let value = makeRandomDict(200)
            let encoder = Lib0Encoder()
            encoder.writeAny(value)
            
            let decoder = Lib0Decoder(data: encoder.data)
            let dvalue = try XCTUnwrap(decoder.readAny() as? [String: Int])
            XCTAssertEqual(dvalue, value)
        }
    }

    private func makeRandomString(_ count: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString = ""
        for _ in 0..<count {
            randomString += String(letters.randomElement()!)
        }
        return randomString
    }
    
    private func makeRandomDict(_ count: Int) -> [String: Int] {
        var result = [String: Int]()
        for _ in 0..<count {
            result[makeRandomString(10)] = Int.random(in: Int.min/64...Int.max/64)
        }
        return result
    }
}
