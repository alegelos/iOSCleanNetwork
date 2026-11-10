import Foundation
import iOSCleanNetwork

/// Mock implementation of `NetworkSessionProtocol` that loads response data
/// from a local JSON file instead of performing a real network call.
/// It does not build `setup.request`, validate HTTP status codes or provide configurable
/// HTTP responses. Test outgoing requests and HTTP error/retry behavior separately.
public final class MockedURLSession: NetworkSessionProtocol {

    public init() {}

    public func data(for apiRequestSetup: ApiSetupProtocol) async throws -> (Data, URLResponse) {
        guard let urlSessionSetup = apiRequestSetup as? URLSessionSetupProtocol else {
            throw Errors.invalidMockedRequestSetup
        }

        let jsonData = try JSONReader.localJSON(
            urlSessionSetup.jsonFileName,
            in: urlSessionSetup.jsonBundle
        )

        return (jsonData, HTTPURLResponse())
    }

    public func dataWithUnauthorizedRefreshRetry(
        apiAccessProvider: ApisGatewayProtocol,
        buildEndpoint: (String) -> ApiSetupProtocol
    ) async throws -> (Data, URLResponse) {
        do {
            let apiAccessToken = try await apiAccessProvider.apisAccessToken()
            let endpoint = buildEndpoint(apiAccessToken)

            return try await data(for: endpoint)
        } catch ApiErrors.unauthorized {
            let refreshedApiAccessToken = try await apiAccessProvider.apisAccessToken(policy: .forceRefresh)
            let endpoint = buildEndpoint(refreshedApiAccessToken)

            return try await data(for: endpoint)
        }
    }
}

// MARK: - Helping Structure

public extension MockedURLSession {

    enum Errors: Error {
        case invalidMockedRequestSetup
    }
}
