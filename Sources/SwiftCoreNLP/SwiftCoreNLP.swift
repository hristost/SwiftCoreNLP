import Foundation

class CoreNLPServer {
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
    init?(url: String) {
        guard let endpoint = URLComponents(string: url) else { return nil }
        self.endpoint = endpoint
    }

    enum AnnotationError: Error {
        case encodingError
        case noServer
        case emptyResponse
    }

    /// Anotate a text using the CoreNLP server
    /// - Parameters:
    ///     - data: the text to be annotated, in the format specified in `properties`.  Currently,
    ///     only English text is supported
    ///     - properties: properties to be passed to the NLP server, such as which annotators to use
    ///     - callback: closure called when the query is processed. If succesful, returns a
    ///     Edu_Stanford_Nlp_Pipeline_Document as defined in the protobuf specification for CoreNLP.
    func annotate(
        _ data: Data,
        properties: Properties,
        callback: @escaping (Result<Edu_Stanford_Nlp_Pipeline_Document, AnnotationError>) -> Void
    ) {
        var properties = properties
        properties.outputFormat = .serialized
        properties.serializer = .protoBuf
        // Encode the query parameters
        guard
            let propertyData = try? JSONEncoder().encode(properties),
            let propertyJSON = String(data: propertyData, encoding: .utf8)
        else {
            callback(.failure(.encodingError))
            return
        }
        var endpoint = self.endpoint

        endpoint.queryItems = [.init(name: "properties", value: propertyJSON)]

        guard let url = endpoint.url else {
            callback(.failure(.encodingError))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data

        URLSession.shared.dataTask(with: request) {
            data, result, error in

            guard
                let data = data?[2..<data!.count], // First three bytes are a header from java
                let doc = try? Edu_Stanford_Nlp_Pipeline_Document(serializedData: data)
            else {
                callback(.failure(.emptyResponse))
                return
            }
            callback(.success(doc))

        }.resume()
    }

    /// Anotate a text using the CoreNLP server
    /// - Parameters:
    ///     - text: the text to be annotated. Currently, only English text is supported
    ///     - properties: properties to be passed to the NLP server, such as which annotators to use
    ///     - callback: closure called when the query is processed. If succesful, returns a
    ///     Edu_Stanford_Nlp_Pipeline_Document as defined in the protobuf specification for CoreNLP.
    func annotate(
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

