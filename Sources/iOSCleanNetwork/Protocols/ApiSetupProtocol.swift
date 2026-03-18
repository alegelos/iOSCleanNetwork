import Foundation

/// `ApiSetupProtocol` defines the essential contract for any API endpoint in your networking layer:
///
/// - **`request`**: A fully configured `URLRequest` including URL, HTTP method, headers, and body.
/// - **`path`**: The endpoint’s path component appended to the base URL.
/// - **`method`**: The HTTP verb to use (e.g. GET, POST, PUT).
/// - **`headers`**: A dictionary of HTTP header fields; may throw if header construction fails.
/// - **`body`**: Optional HTTP body data for the request.
///
/// By conforming to `ApiSetupProtocol`, each endpoint enum centralizes its own request-building logic,
/// ensuring consistency and reducing boilerplate in your networking client.
public protocol ApiSetupProtocol {

    /// A fully configured URLRequest for this endpoint.
    var request: URLRequest { get throws }

    /// Path component to append to the base URL.
    var path: String { get }

    /// HTTP method.
    var method: HttpMethod { get }

    /// HTTP headers; may throw if header construction fails.
    var headers: [String: String] { get throws }

    /// Optional HTTP body data.
    var body: Data? { get }

    /// Query items
    var queryItems: [URLQueryItem] { get }

}

public enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
}
