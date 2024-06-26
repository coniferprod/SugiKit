import XCTest

@testable import SugiKit

import ByteKit
import SyxPack

final class SourceTests: XCTestCase {
    // This is the data of the single patch A-1 from A4-01.SYX
    // (called "Melo Vox 1").
    let patchData: ByteArray = [
        0x4d, 0x65, 0x6c, 0x6f, 0x20, 0x56, 0x6f, 0x78, 0x20, 0x31,  // s00...s09 = name
        0x64, // s10: volume
        0x20, // s11: effect
        0x06, // s12: submix
        0x04, // s13: source mode, polyphony mode, AM1>2, AM3>4
        0x0c, // s14: active sources + 1st byte of vibrato settings
        
        // s15: bender range, wheel assign
        0x02,  // 0b00000010
        
        0x1c, // s16: 2nd vibrato byte
        0x3f, // s17: wheel depth
        0x39, 0x31, 0x32, 0x32, // s18...s21: auto bend
        0x32, // s22: 3rd vibrato byte
        0x3d, // s23: 4th and last vibrato byte
        0x00, 0x30, 0x00, 0x32, 0x32, // LFO bytes, five in total
        0x32, // press freq

        // source data (4 x 7 = 28 bytes)
        0x00, 0x00, 0x02, 0x03, // delay
        0x00, 0x00, 0x50, 0x40, // wave select h + ks curve
        0x12, 0x12, 0x7e, 0x7f, // wave select l
        0x4c, 0x4c, 0x5a, 0x5b, // coarse + key track
        0x00, 0x34, 0x02, 0x03, // fixed key
        0x2c, 0x37, 0x34, 0x35, // fine
        0x02, 0x02, 0x15, 0x11, // prs>frq sw + vib./a.bend sw + vel.curve
        
        // amplifier data (4 x 11 = 44 bytes)
        0x4b, 0x4b, 0x34, 0x35,  // Sn envelope level
        0x36, 0x36, 0x34, 0x35,  // Sn envelope attack
        0x48, 0x48, 0x34, 0x35,  // Sn envelope decay
        0x5a, 0x5a, 0x34, 0x35,  // Sn envelope sustain
        0x40, 0x40, 0x02, 0x01,  // Sn envelope release
        0x41, 0x41, 0x35, 0x36,  // Sn level mod vel
        0x32, 0x32, 0x35, 0x36,  // Sn level mod prs
        0x2c, 0x2c, 0x35, 0x36,  // Sn level mod ks
        0x32, 0x32, 0x35, 0x36,  // Sn time mod on vel
        0x32, 0x32, 0x35, 0x36,  // Sn time mod off vel
        0x32, 0x32, 0x33, 0x34,  // Sn time mod ks
                
        // filter data (2 x 14 = 28 bytes)
        0x31, 0x51,  // Fn cutoff
        0x02, 0x07,  // Fn resonance, LFO sw
        0x32, 0x34,  // Fn cutoff mod vel
        0x5b, 0x34,  // Fn cutoff mod prs
        0x32, 0x34,  // Fn cutoff mod krs
        0x36, 0x34,  // Fn dcf env dep
        0x32, 0x33,  // Fn dcf env vel dep
        0x56, 0x01,  // Fn dcf env attack
        0x64, 0x02,  // Fn dcf env decay
        0x32, 0x63,  // Fn dcf env sustain
        0x56, 0x01,  // Fn dcf env release
        0x32, 0x33,  // Fn dcf time mod on vel
        0x32, 0x33,  // Fn dcf time mode off vel
        0x32, 0x33,  // Fn dcf time mod ks
        
        // checksum
        0x6e
    ]

    let sourceData: ByteArray = [
        // source data (4 x 7 = 28 bytes)
        0x00, 0x00, 0x02, 0x03, // delay
        0x00, 0x00, 0x50, 0x40, // wave select h + ks curve
        0x12, 0x12, 0x7e, 0x7f, // wave select l
        0x4c, 0x4c, 0x5a, 0x5b, // coarse + key track
        0x00, 0x34, 0x02, 0x03, // fixed key
        0x2c, 0x37, 0x34, 0x35, // fine
        0x02, 0x02, 0x15, 0x11, // prs>frq sw + vib./a.bend sw + vel.curve
    ]
    
    // Wave numbers:
    // S1 = 0 + 001_0010B = 0001_0010B = 18 (wave 19)
    // S2 = same as S1
    // S3 = 0 + 111_1110 = 0111_1110 = 126 (wave 127)
    // S4 = 0 + 111_1111 = 0111_1111 = 127 (wave 128)
    
    func testParseSources() {
        var sources = [Source]()
        
        for i in 0..<SinglePatch.sourceCount {
            let data = sourceData.everyNthByte(n: 4, start: i)
            switch Source.parse(from: data) {
            case .success(let source):
                sources.append(source)
            case .failure(let error):
                XCTFail("\(error)")
            }
        }

        XCTAssertEqual(sources.count, SinglePatch.sourceCount)
        XCTAssertEqual(sources[0].wave.number.value, 19)
        XCTAssertEqual(sources[1].wave.number.value, 19)
        XCTAssertEqual(sources[2].wave.number.value, 127)
        XCTAssertEqual(sources[3].wave.number.value, 128)
    }

    
}

