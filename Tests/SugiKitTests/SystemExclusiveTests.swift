import XCTest
@testable import SugiKit
import SyxPack

final class SystemExclusiveTests: XCTestCase {
    
    func testHeaderFunction() {
        let data: ByteArray = [
            0x00, 0x22, 0x00, 0x04, 0x00, 0x00
        ]
        
        let header = Header(d: data)
        
        XCTAssertEqual(header.function, 0x22)
    }

    func testHeaderChannel() {
        let data: ByteArray = [
            0x00, 0x22, 0x00, 0x04, 0x00, 0x00
        ]
        
        let header = Header(d: data)
        
        // Channel byte is zero going in, adjusted to 1 coming out:
        XCTAssertEqual(header.channel, 1)
    }
}
