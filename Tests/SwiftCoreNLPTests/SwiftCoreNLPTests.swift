import XCTest

@testable import SwiftCoreNLP

// These tests assume that there is already a CoreNLP instance running at localhost:9000
// The first run might fail if the server has not completely initialised

final class SwiftCoreNLPTests: XCTestCase {

    /// Test that we encode the server properties correctly
    func testPropertiesJson() throws {
        let properties = CoreNLPServer.Properties(
            annotators: [.tokenize, .ssplit, .pos],
            outputFormat: .json)
        let expected = """
            {"annotators":"tokenize,ssplit,pos","outputFormat":"json"}
            """

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]

        let json = try String(data: encoder.encode(properties), encoding: .utf8)

        XCTAssertEqual(json, expected)
    }

    func testBasicServerResponse() throws {
        let e = expectation(description: "Server")
        let server = CoreNLPServer(url: "http://localhost:9000/")!
        let text = "The quick brown fox jumped over the lazy dog."
        let serverProperties = CoreNLPServer.Properties(annotators: [.parse], outputFormat: .json)
        var document: Edu_Stanford_Nlp_Pipeline_Document!
        server.annotate(text, properties: serverProperties) {
            result in
            switch result {
            case .success(let doc):
                document = doc
            case .failure(_):
                XCTFail("Server query failed")
            }
            e.fulfill()
        }
        waitForExpectations(timeout: 5.0, handler: nil)

        XCTAssertEqual(document.sentence.count, 1)
        let sentence = document.sentence[0]
        XCTAssertEqual(sentence.token.count, 10)  // 9 words + fullstop

        XCTAssertTrue(sentence.hasParseTree)

        // Trasverse parse tree and verify all tokens are included
        var sentenceTokens = sentence.token.reversed().map { $0.word }

        var toVisit: [Edu_Stanford_Nlp_Pipeline_ParseTree] = [sentence.parseTree]
        while let tree = toVisit.popLast() {
            if tree.child.isEmpty {
                // Leaf node -- contains a token
                let token = tree.value
                XCTAssertEqual(token, sentenceTokens.popLast())
            } else {
                // Branch node -- constituent
                toVisit += tree.child.reversed()
            }
        }
    }

    func testTwoSentences() throws {
        let e = expectation(description: "Server")
        let server = CoreNLPServer(url: "http://localhost:9000/")!
        let text = """
            Hi. Hello.
            """
        let serverProperties = CoreNLPServer.Properties(annotators: [.parse], outputFormat: .json)
        var document: Edu_Stanford_Nlp_Pipeline_Document!
        server.annotate(text, properties: serverProperties) {
            result in
            switch result {
            case .success(let doc):
                document = doc
            case .failure(_):
                XCTFail("Server query failed")
            }
            e.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)

        XCTAssertEqual(document.sentence.count, 2)
    }

    func testLongParse() throws {
        // The last sentence here is LONG and would easily take up to a minute for a parse.
        let e = expectation(description: "Server")
        let server = CoreNLPServer(url: "http://localhost:9000/")!
        let text = """
            Look again at that dot. That's here. That's home. That's us. On it, everyone you love,
            everyone you know, everyone you ever heard of, every human being who ever was, lived out
            their lives. The aggregate of our joy and suffering, thousands of confident religions,
            ideologies, and economic doctrines, every hunter and forager, every hero and coward,
            every creator and destroyer of civilization, every king and peasant, every young couple
            in love, every mother and father, hopeful child, inventor and explorer, every teacher of
            morals, every corrupt politician, every "superstar," every "supreme leader," every saint
            and sinner in the history of our species lived there--on a mote of dust suspended in a
            sunbeam.
            """ // Carl Sagan, Pale Blue Dot
        let serverProperties = CoreNLPServer.Properties(annotators: [.parse], outputFormat: .json)
        var document: Edu_Stanford_Nlp_Pipeline_Document!
        server.annotate(text, properties: serverProperties) {
            result in
            switch result {
            case .success(let doc):
                document = doc
            case .failure(_):
                XCTFail("Server query failed")
            }
            e.fulfill()
        }
        waitForExpectations(timeout: 60.0, handler: nil)

        XCTAssertEqual(document.sentence.count, 6)
    }

    static var allTests = [
        ("testPropertiesJson", testPropertiesJson)
    ]
}
