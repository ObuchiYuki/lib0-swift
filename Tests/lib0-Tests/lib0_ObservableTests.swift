import XCTest
@testable import lib0

final class lib0_ObservableTests: XCTestCase {
    func testOnAndEmit() throws {
        class A: Observable {
            static let event1 = Event<Int>("event1")
        }
        
        var callCount = 0
        let a = A()
        a.on(A.event1) {
            callCount += 1
            XCTAssertEqual($0, 120)
        }
        a.emit(A.event1, 120)
        
        XCTAssertEqual(callCount, 1)
    }
    
    func testOff() throws {
        class A: Observable {
            static let event1 = Event<Int>("event1")
        }
        
        var callCount = 0
        let a = A()
        let disposer = a.on(A.event1) {
            callCount += 1
            XCTAssertEqual($0, 120)
        }
        XCTAssertTrue(a.isObserving(A.event1))
        a.emit(A.event1, 120)
        a.off(A.event1, disposer)
        XCTAssertFalse(a.isObserving(A.event1))
        a.emit(A.event1, 121)
        
        XCTAssertEqual(callCount, 1)
    }
}
