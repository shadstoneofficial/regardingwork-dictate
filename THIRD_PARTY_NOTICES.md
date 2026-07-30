# Third-party notices

RegardingWork Dictate preserves the original MIT license and copyright in
[LICENSE](LICENSE). It is derived from the Parrot project maintained by
Digimata / Andrew Jones. See [UPSTREAM.md](UPSTREAM.md).

Swift Package Manager resolves the versions recorded in `Package.resolved`.
The dependency licenses inspected for this revision are:

| Package | Resolved version | License |
|---|---:|---|
| Apple swift-argument-parser | 1.7.1 | Apache-2.0 |
| Argmax WhisperKit | 0.18.0 | MIT |
| Apple swift-asn1 | 1.7.0 | Apache-2.0 |
| Apple swift-collections | 1.5.0 | Apache-2.0 |
| Apple swift-crypto | 4.5.0 | Apache-2.0 |
| Hugging Face swift-jinja | 2.3.5 | Apache-2.0 |
| Hugging Face swift-transformers | 1.1.9 | Apache-2.0 |
| yyjson | 0.12.0 | MIT |

The complete license texts are available in each dependency's source
repository and SwiftPM checkout. Release preparation must re-check the resolved
graph and notices whenever `Package.resolved` changes.

Whisper model files are downloaded separately and are not committed or bundled
in this repository. Review the model provider's license and terms before
distribution or pilot deployment.
