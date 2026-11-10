import Foundation

/// Associates a consumer Setup with a JSON response fixture for `MockedURLSession`.
/// Add this conformance in the consumer's test target to keep test resources out of runtime code.
public protocol URLSessionSetupProtocol {

    /// Resource name without the `.json` extension.
    var jsonFileName: String { get }
    /// Bundle that contains the fixture. Override with `.module` for SwiftPM test resources,
    /// or the owning test/framework bundle in an Xcode project.
    var jsonBundle: Bundle { get }

}

public extension URLSessionSetupProtocol {
    /// Suitable only when the fixture is actually in the main bundle.
    var jsonBundle: Bundle { .main }
}
