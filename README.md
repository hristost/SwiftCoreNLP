# SwiftCoreNLP

Swift bindings for Stanford's [CoreNLP server](https://stanfordnlp.github.io/CoreNLP/).

## Usage

This package communicates with an instance of a CoreNLP server. You need to start the server youself.
To do so locally, run `edu.stanford.nlp.pipeline.StanfordCoreNLPServer` with Java from the
appropriate folder:

```sh
java -mx4g -cp "*" edu.stanford.nlp.pipeline.StanfordCoreNLPServer -port 9000
```

Take note of the server address. Then, to communicate with the server in swift, intiialise a
`CoreNLPServer` instance:

```swift
let server = CoreNLPServer(url: "http://localhost:9000/")!
```

and feed it with text to parse:

```swift
server.annotate("Hello world" , properties: serverProperties) { result in
    switch result {
    case .success(let doc):
        // doc is a Edu_Stanford_Nlp_Pipeline_Document struct that contains everything about the
        // parse you requested. Look up the structure in the `CoreNLP.pb.swift`
        ()
    case .failure(_):
        // Server query failed -- likely a severed connection
        ()
    }
}
```
