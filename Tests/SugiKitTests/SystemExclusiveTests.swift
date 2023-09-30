import XCTest
@testable import SugiKit
import SyxPack

final class SystemExclusiveTests: XCTestCase {
    
    func testHeaderFunction() {
        let data: ByteArray = [
            0x00, 0x22, 0x00, 0x04, 0x00, 0x00
        ]
        
        switch Header.parse(from: data) {
        case .success(let header):
            XCTAssertEqual(header.function, .allPatchDataDump)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }

    func testHeaderChannel() {
        let data: ByteArray = [
            0x00, 0x22, 0x00, 0x04, 0x00, 0x00
        ]
        
        switch Header.parse(from: data) {
        case .success(let header):
            // Channel byte is zero going in, adjusted to 1 coming out:
            XCTAssertEqual(header.channel.value, 1)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }
}
