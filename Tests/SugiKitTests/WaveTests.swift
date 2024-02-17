import XCTest

import SyxPack

@testable import SugiKit


final class WaveTests: XCTestCase {
    func testWaveName() {
        let wave = Wave(number: 10)
        XCTAssertEqual(wave.name, "SAW 1")
    }

    func testWaveNumber() {
        let wave = Wave(number: 96)
        XCTAssertEqual(wave.number.value, 96)
    }
    
    func testWaveNumberFromSystemExclusive() {
        let highByte: Byte = 0b0101_0000  // 0x50 (ws h + ks curve)
        let lowByte: Byte = 0b0001_0010   // 0x12 (ws l)
        // These make up the wave number 18, which is adjusted by +1
        let wave = Wave(highByte: highByte, lowByte: lowByte)
        XCTAssertEqual(wave.number.value, 19)
    }
}
