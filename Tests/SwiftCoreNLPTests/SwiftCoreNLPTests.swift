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
        XCTAssertEqual(sentence.token.count, 10) // 9 words + fullstop

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

    static var allTests = [
        ("testPropertiesJson", testPropertiesJson)
    ]
}
