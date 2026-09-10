import Foundation
import Testing
@testable import OnDeviceSummary

struct UTF8StreamAssemblerTests {
    @Test func reassemblesThreeByteCharacterAcrossChunks() throws {
        let assembler = UTF8StreamAssembler()
        let bytes = Array("日".utf8)

        #expect(assembler.consume(Data(bytes[..<1])) == nil)
        #expect(assembler.consume(Data(bytes[1..<2])) == nil)
        #expect(assembler.consume(Data(bytes[2...])) == "日")
    }

    @Test func reassemblesFourByteCharacterAcrossChunks() throws {
        let assembler = UTF8StreamAssembler()
        let bytes = Array("😀".utf8)

        #expect(assembler.consume(Data(bytes[..<2])) == nil)
        #expect(assembler.consume(Data(bytes[2...])) == "😀")
    }

    @Test func discardsInvalidByteAndResynchronizes() {
        let assembler = UTF8StreamAssembler()
        let data = Data([0xFF]) + Data("復".utf8)

        #expect(assembler.consume(data) == "復")
    }

    @Test func flushDiscardsIncompleteTail() {
        let assembler = UTF8StreamAssembler()
        let bytes = Array("日".utf8)

        #expect(assembler.consume(Data(bytes[..<2])) == nil)
        #expect(assembler.flush() == nil)
        #expect(assembler.consume(Data("後".utf8)) == "後")
    }
}
