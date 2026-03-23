# iOSCleanNetwork

`iOSCleanNetwork` is a lightweight Swift Package for building API clients with a clear and predictable structure.

The package is based on two simple conventions:

- types ending in **`Setup`** define endpoint configuration
- types ending in **`Provider`** execute the request and decode the response

It also keeps the transport layer abstract through `NetworkSessionProtocol`, so tests do not require mocking the Provider at all. You can keep the exact same production Provider, inject `MockedURLSession`, provide the expected JSON fixtures, and let the same decoding flow used in production return the response.

## Package products

### `iOSCleanNetwork`
Runtime networking module.

Use it for:

- endpoint configuration through `ApiSetupProtocol`
- request execution through `NetworkSessionProtocol`
- response validation
- unauthorized retry orchestration through `ApisGatewayProtocol`

### `iOSCleanNetworkTesting`
Testing support module.

Use it for:

- `MockedURLSession`
- `JSonReader`
- `URLSessionSetupProtocol`
- fixture-based testing without changing the Provider implementation

## Design conventions

### `*Setup`
Any type that defines an endpoint should end with `Setup` and conform to `ApiSetupProtocol`.

A `Setup` is responsible for request configuration only.

Typical responsibilities:

- `path`
- `method`
- `headers`
- `body`
- `queryItems`
- `request`

Examples:

- `GitHubUserAPISetup`
- `StripeAPISetup`
- `SpotifyAPISetup`

The goal is simple: when someone reads `Setup`, they should immediately know that it contains endpoint configuration.

### `*Provider`
Any type that performs the request should end with `Provider`.

A `Provider` is responsible for:

- receiving dependencies such as `baseURL`, `apiAccessProvider`, and `session`
- building the correct `Setup`
- executing the request through the injected session
- decoding the response model
- returning the decoded result

Examples:

- `GitHubUserAPIProvider`
- `StripeAPIProvider`
- `SpotifyAPIProvider`

## Transport model naming

Use the following naming consistently:

- **`*Response`** for direct responses coming from the API
- **`*DTO`** for parameters or payloads you send to the API in the request

Examples:

- `GitHubUserResponse`
- `StripePaymentIntentResponse`
- `CreatePaymentIntentDTO`
- `CreateCardTokenDTO`

This keeps transport models easy to identify at a glance.

## Installation

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "YourFeature",
    dependencies: [
        .package(url: "https://github.com/alegelos/iOSCleanNetwork", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourFeature",
            dependencies: [
                .product(name: "iOSCleanNetwork", package: "iOSCleanNetwork")
            ]
        ),
        .testTarget(
            name: "YourFeatureTests",
            dependencies: [
                "YourFeature",
                .product(name: "iOSCleanNetworkTesting", package: "iOSCleanNetwork")
            ]
        )
    ]
)
```

## Runtime usage

## Example: one API with both a GET service and a POST service

This example shows the most common setup in a single module:

- one `GET` endpoint without body
- one `POST` endpoint with body
- one `Setup`
- one `Provider`

### 1. Define request DTOs and response models

```swift
import Foundation

struct CreatePaymentIntentDTO: Encodable {
    let amount: Int
    let currency: String
    let captureMethod: String

    enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case captureMethod = "capture_method"
    }
}

struct StripePaymentIntentResponse: Decodable {
    let id: String
    let status: String
    let clientSecret: String?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case clientSecret = "client_secret"
    }
}
```

### 2. Define a `Setup`

```swift
import Foundation
import iOSCleanNetwork

enum StripeAPISetup: ApiSetupProtocol {
    case retrievePaymentIntent(
        baseURL: URL,
        secretAPIKey: String,
        paymentIntentID: String
    )
    case createPaymentIntent(
        baseURL: URL,
        secretAPIKey: String,
        paymentIntentDTO: CreatePaymentIntentDTO
    )

    var request: URLRequest {
        get throws {
            let requestBaseURL: URL

            switch self {
            case let .retrievePaymentIntent(baseURL, _, _),
                 let .createPaymentIntent(baseURL, _, _):
                requestBaseURL = baseURL
            }

            let fullURL = requestBaseURL.appendingPathComponent(path)

            guard var urlComponents = URLComponents(
                url: fullURL,
                resolvingAgainstBaseURL: false
            ) else {
                throw ApiErrors.invalidUrl
            }

            urlComponents.queryItems = queryItems.isEmpty ? nil : queryItems

            guard let resolvedURL = urlComponents.url else {
                throw ApiErrors.invalidUrl
            }

            var urlRequest = URLRequest(url: resolvedURL)
            urlRequest.httpMethod = method.rawValue

            for (field, value) in try headers {
                urlRequest.setValue(value, forHTTPHeaderField: field)
            }

            urlRequest.httpBody = body
            return urlRequest
        }
    }

    var path: String {
        switch self {
        case let .retrievePaymentIntent(_, _, paymentIntentID):
            return "payment_intents/\(paymentIntentID)"
        case .createPaymentIntent:
            return "payment_intents"
        }
    }

    var method: HttpMethod {
        switch self {
        case .retrievePaymentIntent:
            return .get
        case .createPaymentIntent:
            return .post
        }
    }

    var headers: [String: String] {
        get throws {
            let secretAPIKey: String

            switch self {
            case let .retrievePaymentIntent(_, key, _),
                 let .createPaymentIntent(_, key, _):
                secretAPIKey = key
            }

            return [
                "Authorization": "Bearer \(secretAPIKey)",
                "Accept": "application/json",
                "Content-Type": "application/json"
            ]
        }
    }

    var body: Data? {
        let jsonEncoder = JSONEncoder()

        switch self {
        case .retrievePaymentIntent:
            return nil

        case let .createPaymentIntent(_, _, paymentIntentDTO):
            return try? jsonEncoder.encode(paymentIntentDTO)
        }
    }

    var queryItems: [URLQueryItem] {
        []
    }
}
```

### 3. Define a `Provider`

```swift
import Foundation
import iOSCleanNetwork

protocol StripeAPIProviding {
    func retrievePaymentIntent(
        secretAPIKey: String,
        paymentIntentID: String
    ) async throws -> StripePaymentIntentResponse

    func createPaymentIntent(
        secretAPIKey: String,
        paymentIntentDTO: CreatePaymentIntentDTO
    ) async throws -> StripePaymentIntentResponse
}

final class StripeAPIProvider: StripeAPIProviding {
    private let baseURL: URL
    private let session: any NetworkSessionProtocol

    init(
        baseURL: URL,
        session: any NetworkSessionProtocol = URLSession.shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func retrievePaymentIntent(
        secretAPIKey: String,
        paymentIntentID: String
    ) async throws -> StripePaymentIntentResponse {
        let setup = StripeAPISetup.retrievePaymentIntent(
            baseURL: baseURL,
            secretAPIKey: secretAPIKey,
            paymentIntentID: paymentIntentID
        )

        let (data, _) = try await session.data(for: setup)
        return try JSONDecoder().decode(StripePaymentIntentResponse.self, from: data)
    }

    func createPaymentIntent(
        secretAPIKey: String,
        paymentIntentDTO: CreatePaymentIntentDTO
    ) async throws -> StripePaymentIntentResponse {
        let setup = StripeAPISetup.createPaymentIntent(
            baseURL: baseURL,
            secretAPIKey: secretAPIKey,
            paymentIntentDTO: paymentIntentDTO
        )

        let (data, _) = try await session.data(for: setup)
        return try JSONDecoder().decode(StripePaymentIntentResponse.self, from: data)
    }
}
```

### 4. Use the `Provider`

```swift
import Foundation

let provider = StripeAPIProvider(
    baseURL: URL(string: "https://api.stripe.com/v1")!
)

// GET example
let existingPaymentIntent = try await provider.retrievePaymentIntent(
    secretAPIKey: "sk_test_123",
    paymentIntentID: "pi_123"
)

// POST example
let createdPaymentIntent = try await provider.createPaymentIntent(
    secretAPIKey: "sk_test_123",
    paymentIntentDTO: CreatePaymentIntentDTO(
        amount: 1_999,
        currency: "usd",
        captureMethod: "automatic"
    )
)
```

This keeps the pattern easy to read:

- `StripeAPISetup` contains both endpoint configurations
- `StripeAPIProvider` contains both service methods
- the `GET` endpoint has no body
- the `POST` endpoint encodes a DTO into the body


## Unauthorized retry and token refresh

`iOSCleanNetwork` is authentication-agnostic.

The package does **not** implement OAuth 2.0 or token refresh by itself. Instead, it depends on `ApisGatewayProtocol`, which must be implemented by the consumer.

That means your app or SDK can decide how tokens are obtained:

- custom OAuth 2.0 implementation
- AppAuth
- internal authentication SDK
- any other token provider

When a request fails with `ApiErrors.unauthorized`, the session can:

1. ask the gateway for an access token
2. execute the request
3. if it receives `401 Unauthorized`, request a refreshed token with `.forceRefresh`
4. rebuild the `Setup`
5. retry once

### Example gateway

```swift
import Foundation
import iOSCleanNetwork

final class SampleApisGatewayProvider: ApisGatewayProtocol {
    func apisAccessToken(policy: AccessTokenPolicy) async throws -> String {
        switch policy {
        case .useCache:
            return "cached-access-token"
        case .forceRefresh:
            return "refreshed-access-token"
        }
    }
}
```

### Example Provider using refresh retry

```swift
import Foundation
import iOSCleanNetwork

struct SpotifyProfileResponse: Decodable {
    let id: String
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }
}

enum SpotifyAPISetup: ApiSetupProtocol {
    case profile(baseURL: URL, accessToken: String)

    var request: URLRequest {
        get throws {
            let fullURL = baseURL.appendingPathComponent(path)
            var urlRequest = URLRequest(url: fullURL)
            urlRequest.httpMethod = method.rawValue

            for (field, value) in try headers {
                urlRequest.setValue(value, forHTTPHeaderField: field)
            }

            return urlRequest
        }
    }

    private var baseURL: URL {
        switch self {
        case let .profile(baseURL, _):
            return baseURL
        }
    }

    var path: String { "me" }
    var method: HttpMethod { .get }
    var headers: [String: String] {
        get throws {
            switch self {
            case let .profile(_, accessToken):
                return [
                    "Authorization": "Bearer \(accessToken)",
                    "Accept": "application/json"
                ]
            }
        }
    }
    var body: Data? { nil }
    var queryItems: [URLQueryItem] { [] }
}

final class SpotifyAPIProvider {
    private let baseURL: URL
    private let apiAccessProvider: ApisGatewayProtocol
    private let session: any NetworkSessionProtocol

    init(
        baseURL: URL,
        apiAccessProvider: ApisGatewayProtocol,
        session: any NetworkSessionProtocol = URLSession.shared
    ) {
        self.baseURL = baseURL
        self.apiAccessProvider = apiAccessProvider
        self.session = session
    }

    func fetchProfile() async throws -> SpotifyProfileResponse {
        let (data, _) = try await session.dataWithUnauthorizedRefreshRetry(
            apiAccessProvider: apiAccessProvider,
            buildEndpoint: { accessToken in
                SpotifyAPISetup.profile(
                    baseURL: self.baseURL,
                    accessToken: accessToken
                )
            }
        )

        return try JSONDecoder().decode(SpotifyProfileResponse.self, from: data)
    }
}
```

## Testing with `MockedURLSession`

The testing approach is intentionally simple:

**the Provider does not change.**

The same Provider used in production is used in tests.
The only thing that changes is the injected session.

In production:

- inject `URLSession.shared`

In tests:

- inject `MockedURLSession`

That means:

- same Provider
- same Setup
- same decode logic
- different session implementation only

## Extra requirement for fixture-based testing

To use `MockedURLSession`, the `Setup` must also conform to `URLSessionSetupProtocol`.

That protocol provides the `jsonFileName` that should be loaded from the test bundle.

```swift
import Foundation
import iOSCleanNetwork
import iOSCleanNetworkTesting

extension GitHubUserAPISetup: URLSessionSetupProtocol {
    var jsonFileName: String {
        switch self {
        case .user:
            return "githubUser"
        }
    }
}
```

## How `MockedURLSession` works

`MockedURLSession` conforms to `NetworkSessionProtocol`.

When `data(for:)` is called:

1. it receives the same `Setup` your Provider uses in production
2. it checks whether that `Setup` also conforms to `URLSessionSetupProtocol`
3. it reads `jsonFileName`
4. it loads the JSON file using `JSonReader`
5. it returns the JSON as `Data`
6. the same Provider decodes that data and returns the response model

That means you do **not** need to rewrite the Provider for testing.

## Example test

```swift
import Testing
import Foundation
import iOSCleanNetwork
import iOSCleanNetworkTesting

struct GitHubUserAPIProviderTests {
    @Test
    func fetchUser_returnsDecodedFixture() async throws {
        // Given
        let baseURL = URL(string: "https://api.github.com")!
        let session = MockedURLSession()
        let provider = GitHubUserAPIProvider(
            baseURL: baseURL,
            session: session
        )

        // When
        let response = try await provider.fetchUser(username: "octocat")

        // Then
        #expect(response.login == "octocat")
    }
}
```

## Spy support

Spy support follows a different pattern than fixture-based transport testing.

- `MockedURLSession` is provided by `iOSCleanNetworkTesting`
- `ProviderSpyProtocol` is provided by the framework
- **concrete provider spies are still written by hand by the consumer**
- an optional service-level spy that aggregates several provider spies is also **written by hand by the consumer**

This keeps the framework lightweight while still giving you a reusable base contract for invocation counting, queued failures, and assertions.

### What the framework provides

The framework provides `ProviderSpyProtocol`.

Its job is to standardize the common spy behavior:

- count how many times each method was called
- queue failures per method
- consume failures in insertion order for the matching method
- assert expected invocation counts
- reset counters between tests

That means the repeated boilerplate is small and predictable, but the final concrete spy still belongs to the consumer because only the consumer knows the real protocol being wrapped.

### What the consumer writes by hand

For each provider protocol you want to observe in tests, you usually write one spy manually.

That spy typically contains:

- a `MethodKey` enum
- `invocationsCount`
- `failingMethos`
- a wrapped real implementation
- one forwarding method per protocol requirement

The pattern is always the same:

1. increment the invocation count
2. validate whether that method should fail
3. forward the call to the wrapped provider

### Example provider spy

```swift
import Foundation
import iOSCleanNetworkTesting

final class GitHubUserAPIProviderSpy: ProviderSpyProtocol {
    enum MethodKey: String, Hashable, CaseIterable {
        case fetchUser
        case fetchRepositories
    }

    var invocationsCount: [MethodKey: Int] = [:]
    var failingMethos: [(method: MethodKey, error: Error)] = []

    private let wrappedProvider: any GitHubUserAPIProviding

    init(wrapping wrappedProvider: any GitHubUserAPIProviding) {
        self.wrappedProvider = wrappedProvider
    }
}

extension GitHubUserAPIProviderSpy: GitHubUserAPIProviding {
    func fetchUser(username: String) async throws -> GitHubUserResponse {
        increment(.fetchUser)
        try validateFailingMethods(method: .fetchUser)
        return try await wrappedProvider.fetchUser(username: username)
    }

    func fetchRepositories(username: String) async throws -> [GitHubRepositoryResponse] {
        increment(.fetchRepositories)
        try validateFailingMethods(method: .fetchRepositories)
        return try await wrappedProvider.fetchRepositories(username: username)
    }
}
```

This is intentionally handwritten.

The framework does **not** try to auto-generate the spy because the consumer still needs to decide:

- which protocol is being wrapped
- which methods are relevant to the test suite
- whether a higher-level aggregated service spy is useful

## Optional service-level spy

When tests exercise a higher-level service, asserting each provider spy manually in every test becomes noisy.

A common pattern is to create a service-level spy that owns several provider spies and exposes a single testing API.

This service-level spy is **also consumer code**, not framework code.

Typical responsibilities:

- build and own the individual provider spies
- expose `resetAllCounters()`
- expose `failingMethods(...)`
- expose `assertExpectedInvocations(...)`
- centralize all assertion ergonomics in one place

### Example service-level spy

```swift
import Foundation
import Testing

final class GitHubProfileServiceSpy: GitHubProfileService {
    private let userAPIProviderSpy: GitHubUserAPIProviderSpy
    private let authGatewayProviderSpy: GitHubAuthGatewayProviderSpy

    init(
        userAPIProvider: any GitHubUserAPIProviding,
        authGatewayProvider: any GitHubAuthGatewayProviding
    ) {
        self.userAPIProviderSpy = GitHubUserAPIProviderSpy(wrapping: userAPIProvider)
        self.authGatewayProviderSpy = GitHubAuthGatewayProviderSpy(wrapping: authGatewayProvider)

        super.init(
            userAPIProvider: userAPIProviderSpy,
            authGatewayProvider: authGatewayProviderSpy
        )
    }
}
```

### Aggregate invocation assertions

```swift
import Testing

extension GitHubProfileServiceSpy {
    enum MethodsKeys {
        case userAPI([(GitHubUserAPIProviderSpy.MethodKey, Int)])
        case authGateway([(GitHubAuthGatewayProviderSpy.MethodKey, Int)])

        static func userAPI(_ keys: GitHubUserAPIProviderSpy.MethodKey...) -> Self {
            .userAPI(keys.map { ($0, 1) })
        }

        static func userAPI(_ items: (GitHubUserAPIProviderSpy.MethodKey, times: Int)...) -> Self {
            .userAPI(items.map { ($0.0, $0.times) })
        }

        static func authGateway(_ keys: GitHubAuthGatewayProviderSpy.MethodKey...) -> Self {
            .authGateway(keys.map { ($0, 1) })
        }

        static func authGateway(_ items: (GitHubAuthGatewayProviderSpy.MethodKey, times: Int)...) -> Self {
            .authGateway(items.map { ($0.0, $0.times) })
        }
    }

    func assertExpectedInvocations(
        _ expectedCalls: MethodsKeys...,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        enum Provider: CaseIterable {
            case userAPI
            case authGateway
        }

        var seenProviders = Set<Provider>()

        for expectedCall in expectedCalls {
            switch expectedCall {
            case .userAPI(let expected):
                seenProviders.insert(.userAPI)
                userAPIProviderSpy.assertExpectedInvocations(expected, sourceLocation: sourceLocation)

            case .authGateway(let expected):
                seenProviders.insert(.authGateway)
                authGatewayProviderSpy.assertExpectedInvocations(expected, sourceLocation: sourceLocation)
            }
        }

        for provider in Provider.allCases where seenProviders.contains(provider) == false {
            switch provider {
            case .userAPI:
                userAPIProviderSpy.assertExpectedInvocations([], sourceLocation: sourceLocation)
            case .authGateway:
                authGatewayProviderSpy.assertExpectedInvocations([], sourceLocation: sourceLocation)
            }
        }
    }

    func resetAllCounters() {
        userAPIProviderSpy.resetInvocationsCount()
        authGatewayProviderSpy.resetInvocationsCount()
    }
}
```

### Aggregate failure injection

```swift
import Foundation

extension GitHubProfileServiceSpy {
    enum FailingMethods {
        case userAPI([(GitHubUserAPIProviderSpy.MethodKey, Error)])
        case authGateway([(GitHubAuthGatewayProviderSpy.MethodKey, Error)])

        static func userAPI(
            _ keys: GitHubUserAPIProviderSpy.MethodKey...,
            error: Error = GitHubProfileServiceSpyError.forcedFailure
        ) -> Self {
            .userAPI(keys.map { ($0, error) })
        }

        static func authGateway(
            _ keys: GitHubAuthGatewayProviderSpy.MethodKey...,
            error: Error = GitHubProfileServiceSpyError.forcedFailure
        ) -> Self {
            .authGateway(keys.map { ($0, error) })
        }
    }

    func failingMethods(_ failingMethods: FailingMethods...) {
        for failingMethod in failingMethods {
            switch failingMethod {
            case .userAPI(let methods):
                userAPIProviderSpy.failingMethods(methods)
            case .authGateway(let methods):
                authGatewayProviderSpy.failingMethods(methods)
            }
        }
    }
}

private enum GitHubProfileServiceSpyError: Error {
    case forcedFailure
}
```

## Example tests using the service-level spy

The end goal of the service-level spy is test ergonomics.

Instead of checking every wrapped spy manually, tests stay short and readable.

```swift
import Testing

struct GitHubProfileServiceTests {
    @Test
    func loadProfile_succeeds() async throws {
        // Given
        let service = GitHubProfileServiceSpy(
            userAPIProvider: StubGitHubUserAPIProvider.success,
            authGatewayProvider: StubGitHubAuthGatewayProvider.success
        )
        service.resetAllCounters()

        // When
        let actualProfile = try await service.loadProfile(username: "octocat")

        // Then
        #expect(actualProfile.login == "octocat")
        service.assertExpectedInvocations(
            .authGateway(.accessToken),
            .userAPI(.fetchUser)
        )
    }

    @Test
    func loadProfile_throwsWhenUserRequestFails() async throws {
        // Given
        let service = GitHubProfileServiceSpy(
            userAPIProvider: StubGitHubUserAPIProvider.success,
            authGatewayProvider: StubGitHubAuthGatewayProvider.success
        )
        service.resetAllCounters()
        service.failingMethods(.userAPI(.fetchUser))

        // When
        do {
            _ = try await service.loadProfile(username: "octocat")
            Issue.record("Expected loadProfile to throw forcedFailure")
        } catch {
            // Then
            #expect(error is GitHubProfileServiceSpyError)
            service.assertExpectedInvocations(
                .authGateway(.accessToken),
                .userAPI(.fetchUser)
            )
        }
    }
}
```

### Why this split matters

There are three different testing layers here:

1. **Fixture-based transport testing**
   - provided by the framework through `MockedURLSession`
   - no Provider mocking required
   - just provide JSON fixtures

2. **Concrete provider spies**
   - written by hand by the consumer
   - built on top of `ProviderSpyProtocol`
   - useful for counting calls and injecting failures

3. **Optional service-level spy**
   - also written by hand by the consumer
   - groups several provider spies behind one small testing API
   - keeps higher-level tests very short

The framework only provides the reusable building blocks.
The final spy types and test surface are intentionally user-defined.

## Summary

`iOSCleanNetwork` is built around a simple idea:

- `Setup` configures the endpoint
- `Provider` performs the request and decodes the response
- the session is injected
- authentication remains external through `ApisGatewayProtocol`
- in tests, the same `Provider` can run unchanged by swapping the session for `MockedURLSession`

That keeps both production and test code simple, explicit, and easy to maintain.
