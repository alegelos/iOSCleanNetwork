import Foundation

/// `ApiProvider` defines the core contract for any service that supplies API calls in your networking layer:
///
/// - **`baseURL`**: The root URL for all endpoint requests built by this provider.
/// - **`session`**: The network session responsible for executing `URLRequest`s and returning responses.
///
/// This optional protocol exposes configuration only; it provides no request execution
/// or decoding implementation. Consumer providers can instead conform directly to their
/// feature's Domain protocol and inject a `NetworkSessionProtocol`.
public protocol ApiProvider {

    /// Root URL used to construct each endpoint’s full URL.
    var baseURL: URL { get }

    /// Networking session used to perform HTTP requests.
    var session: NetworkSessionProtocol { get }

}
