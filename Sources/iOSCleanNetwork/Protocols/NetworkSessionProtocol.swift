import Foundation

/// `NetworkSessionProtocol` abstracts the network transport layer:
///
/// - **`data(for:)`**: Executes the given `ApiSetupProtocol` request by building its `URLRequest`,
///   performs it asynchronously, and returns the raw `Data` and `URLResponse`.
/// - **`dataWithUnauthorizedRefreshRetry`**: Obtains an app-supplied token and, after
///   `ApiErrors.unauthorized`, forces one refresh and rebuilds the endpoint for one retry.
///
/// Conforming types (e.g. `URLSession`) can integrate seamlessly, enabling easy mocking or
/// alternative transports for testing or customization. A custom conformer implements
/// both methods; the protocol itself supplies no default transport or retry behavior.
public protocol NetworkSessionProtocol: AnyObject, Sendable {

    @discardableResult
    func data(for apiRequestSetup: ApiSetupProtocol) async throws -> (Data, URLResponse)

    @discardableResult
    func dataWithUnauthorizedRefreshRetry(
        apiAccessProvider: ApisGatewayProtocol,
        buildEndpoint: (String) -> ApiSetupProtocol
    ) async throws -> (Data, URLResponse)

}
