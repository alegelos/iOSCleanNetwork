import Foundation

/// `ApiProvider` defines the core contract for any service that supplies API calls in your networking layer:
///
/// - **`baseURL`**: The root URL for all endpoint requests built by this provider.
/// - **`session`**: The network session responsible for executing `URLRequest`s and returning responses.
///
/// Conforming types centralize their configuration (base URL and session) to keep client code concise
/// and allow shared request construction logic to operate on a common interface.
public protocol ApiProvider {

    /// Root URL used to construct each endpoint’s full URL.
    var baseURL: URL { get }

    /// Networking session used to perform HTTP requests.
    var session: NetworkSessionProtocol { get }

}
