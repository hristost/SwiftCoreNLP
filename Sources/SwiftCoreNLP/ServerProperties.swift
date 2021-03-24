public extension CoreNLPServer {

    struct Properties: Encodable {
        public enum Annotator: String, Encodable {
            case tokenize, ssplit, pos, parse
        }
        public enum Format: String, Encodable {
            case json, xml, text, serialized
        }
        public enum Serializer: String, Encodable {
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
        @StringArray public var annotators: [Annotator]? = nil
        public var outputFormat: Format? = nil
        public var inputFormat: Format? = nil
        public var serializer: Serializer? = nil

        public init(
            annotators: [Annotator]? = nil,
            outputFormat: Format? = nil,
            inputFormat: Format? = nil,
            serializer: Serializer? = nil
        ) {
            self.annotators = annotators
            self.outputFormat = outputFormat
            self.inputFormat = inputFormat
            self.serializer = serializer
        }

    }
}

@propertyWrapper public struct StringArray<T: RawRepresentable>: Encodable
where T.RawValue == String {

    public var wrappedValue: [T]?
    public func encode(to encoder: Encoder) throws {
        guard let vals = self.wrappedValue else { return }
        let str = vals.map { $0.rawValue }.joined(separator: ",")
        try str.encode(to: encoder)
    }

    public init(wrappedValue: [T]?) {
        self.wrappedValue = wrappedValue
    }

}
