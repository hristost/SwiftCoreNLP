import Foundation
import SwiftProtobuf

public class CoreNLPServer {
    /// URL components describing the a path to the server
    var endpoint: URLComponents

    /// Initialise a connection to a CoreNLP server that has already been started and is listening
    /// at the specified URL
    /// - Parameter url: URL for the server, for example, http://0.0.0.0:9000/
    ///
    /// To start the server, use
    ///
    ///     java -mx4g -cp "*" edu.stanford.nlp.pipeline.StanfordCoreNLPServer -port 9000
    ///
    /// in the folder where you downloaded CoreNLP
    public init?(url: String) {
        guard let endpoint = URLComponents(string: url) else { return nil }
        self.endpoint = endpoint
    }

    public enum AnnotationError: Error {
        /// An error occured while preparing data to be sent to the server
        case encodingError
        /// Did not receive response from server
        case emptyResponse
        /// An error occured while decoding output from CoreNLP
        case protobufMismatch(Error)
    }

    /// Anotate a text using the CoreNLP server
    /// - Parameters:
    ///     - data: the text to be annotated, in the format specified in `properties`. Currently,
    ///     only English text is supported
    ///     - properties: properties to be passed to the NLP server, such as which annotators to use
    ///     - callback: closure called when the query is processed. If succesful, returns a
    ///     Edu_Stanford_Nlp_Pipeline_Document as defined in the protobuf specification for CoreNLP.
    public func annotate(
        _ data: Data,
        properties: Properties,
        callback: @escaping (Result<Edu_Stanford_Nlp_Pipeline_Document, AnnotationError>) -> Void
    ) {
        var properties = properties
        properties.outputFormat = .serialized
        properties.serializer = .protoBuf

        // Encode the query parameters.
        // Since we're encoding enums, we don't expect these to fail, so we force-unwrap
        let propertiesJSON = try! String(data: JSONEncoder().encode(properties), encoding: .utf8)!

        var endpoint = self.endpoint

        endpoint.queryItems = [.init(name: "properties", value: propertiesJSON)]

        guard let url = endpoint.url else {
            callback(.failure(.encodingError))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data

        URLSession.shared.dataTask(with: request) {
            data, result, error in

            guard let data = data else {
                callback(.failure(.emptyResponse))
                return
            }

            let stream = InputStream(data: data)
            stream.open()
            defer { stream.close() }

            do {
                let type = Edu_Stanford_Nlp_Pipeline_Document.self
                let doc = try BinaryDelimited.parse(messageType: type, from: stream)
                callback(.success(doc))
            } catch let error {
                callback(.failure(.protobufMismatch(error)))
            }

        }.resume()
    }

    /// Anotate a text using the CoreNLP server
    /// - Parameters:
    ///     - text: the text to be annotated. Currently, only English text is supported
    ///     - properties: properties to be passed to the NLP server, such as which annotators to use
    ///     - callback: closure called when the query is processed. If succesful, returns a
    ///     Edu_Stanford_Nlp_Pipeline_Document as defined in the protobuf specification for CoreNLP.
    public func annotate(
        _ text: String,
        properties: Properties,
        callback: @escaping (Result<Edu_Stanford_Nlp_Pipeline_Document, AnnotationError>) -> Void
    ) {
        guard let data = text.data(using: .utf8) else {
            callback(.failure(.encodingError))
            return
        }
        var properties = properties
        properties.inputFormat = nil
        self.annotate(data, properties: properties, callback: callback)
    }
}
