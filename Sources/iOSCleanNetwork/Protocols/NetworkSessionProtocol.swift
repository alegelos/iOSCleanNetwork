import Foundation

/// `NetworkSessionProtocol` abstracts the network transport layer:
///
/// - **`data(for:)`**: Executes the given `ApiSetupProtocol` request by building its `URLRequest`,
///   performs it asynchronously, and returns the raw `Data` and `URLResponse`.
///
/// Conforming types (e.g. `URLSession`) can integrate seamlessly, enabling easy mocking or
/// alternative transports for testing or customization.
public protocol NetworkSessionProtocol: AnyObject {

    @discardableResult
    func data(for apiRequestSetup: ApiSetupProtocol) async throws -> (Data, URLResponse)

    @discardableResult
    func dataWithUnauthorizedRefreshRetry(
        apiAccessProvider: ApisGatewayProtocol,
        buildEndpoint: (String) -> ApiSetupProtocol
    ) async throws -> (Data, URLResponse)

}
