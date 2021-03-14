public extension CoreNLPServer {

    struct Properties: Encodable {
        enum Annotator: String, Encodable {
            case tokenize, ssplit, pos, parse
        }
        enum Format: String, Encodable {
            case json, xml, text, serialized
        }
        enum Serializer: String, Encodable {
            /// Writes the output to a protocol buffer, as defined in the definition file
            /// `edu.stanford.nlp.pipeline.CoreNLP.proto`
            case protoBuf = "edu.stanford.nlp.pipeline.ProtobufAnnotationSerializer"
            /// Writes the output to a Java serialized object. This is only suitable for
            /// transferring data between Java programs. This also produces relatively large
            ///serialized objects.
            case genericAnnotation = "edu.stanford.nlp.pipeline.GenericAnnotationSerializer"
            /// Writes the output to a (lossy!) textual representation, which is much smaller than
            /// `Serializer.generic`, but does not include all the relevant information
            case custom = "edu.stanford.nlp.pipeline.CustomAnnotationSerializer"

        }
        @StringArray var annotators: [Annotator]? = nil
        var outputFormat: Format? = nil
        var inputFormat: Format? = nil
        var serializer: Serializer? = nil
    }
}

@propertyWrapper struct StringArray<T: RawRepresentable>: Encodable where T.RawValue == String {

    var wrappedValue: [T]?
    func encode(to encoder: Encoder) throws {
        guard let vals = self.wrappedValue else { return }
        let str = vals.map { $0.rawValue }.joined(separator: ",")
        try str.encode(to: encoder)
    }

}
