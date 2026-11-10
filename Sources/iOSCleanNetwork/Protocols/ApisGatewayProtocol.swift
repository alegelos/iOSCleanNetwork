import Foundation

/// The consumer's source of access tokens for protected API requests.
/// Token acquisition, storage and cache/refresh policy are implemented by the consumer.
public protocol ApisGatewayProtocol: AnyObject {

    /// Returns a valid access token suitable for the API's authentication scheme.
    ///
    /// - Parameter policy: Determines whether to reuse a cached token or force-refresh.
    /// - Returns: An OAuth access token string suitable for authenticating API requests.
    /// - Throws: Any network or decoding error encountered during retrieval.
    func apisAccessToken(policy: AccessTokenPolicy) async throws -> String

}

// MARK: Convenience Extension

extension ApisGatewayProtocol {

    /// This is equivalent to calling `apisAccessToken(policy: .default)`.
    public func apisAccessToken() async throws -> String {
        try await apisAccessToken(policy: .default)
    }

}

// MARK: - Access Token Refresh Policy

/// Defines how strictly to refresh your cached token.
public enum AccessTokenPolicy: Sendable {

    /// Token will be valid for at least `minTTL` more seconds, fetching a new one if needed.
    case useCache(minTTL: TimeInterval)
    /// Fetch a fresh token.
    case forceRefresh

    /// Requests a cached token with at least 180 seconds (3 minutes) of validity.
    public static let `default` = AccessTokenPolicy.useCache(minTTL: 180)
}
