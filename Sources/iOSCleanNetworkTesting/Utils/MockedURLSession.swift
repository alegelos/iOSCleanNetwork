import Foundation
import iOSCleanNetwork

/// Use to mock URLSession calls
public final class MockedURLSession: NetworkSessionProtocol {

    public let jsonReader = JSonReader()

    public func data(for apiRequestSetup: ApiSetupProtocol) async throws -> (Data, URLResponse) {
        guard let apiRequestSetup = apiRequestSetup as? URLSessionSetupProtocol else {
            throw Errors.missingJsonFileName
        }

        let jsonFileName = apiRequestSetup.jsonFileName

        let jsonData = try jsonReader.localJSon(jsonFileName)

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
            let apiAccessToken = try await apiAccessProvider.apisAccessToken(policy: .forceRefresh)
            let endpoint = buildEndpoint(apiAccessToken)

            return try await data(for: endpoint)
        }
    }

}

// MARK: - Helping Structure

public extension MockedURLSession {

    enum Errors: Error {
        case missingJsonFileName
    }

}
