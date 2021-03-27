import Foundation
import SwiftProtobuf
import Combine

public extension CoreNLPServer {
    typealias Document = Edu_Stanford_Nlp_Pipeline_Document

    func annotatePublisher(_ text: String, properties: Properties) -> AnyPublisher<Document, AnnotationError> {
        return Deferred {
            Future<Document, AnnotationError> { promise in
                self.annotate(text, properties: properties) { promise($0) }
            }.eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}
