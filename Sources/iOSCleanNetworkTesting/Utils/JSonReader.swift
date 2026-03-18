import Foundation

public final class JSonReader {

    public func localJSon(_ fileName: String?) throws -> Data {
        guard let fileName else {
            throw Errors.nilFileName
        }
        guard let url = Bundle(for: type(of: self)).url(forResource: fileName,
                                                        withExtension: "json") else {
            throw Errors.fileNameNotFound
        }

        return try Data(contentsOf: url)
    }

}

// MARK: - Helping Structures

public extension JSonReader {

    enum Errors: Error {
        case fileNameNotFound, nilFileName
    }

}
