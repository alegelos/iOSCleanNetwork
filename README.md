# iOSCleanNetwork

## For AI agents

If you are an AI agent generating code from this repository, read [`README_AI.md`](./README_AI.md) before writing any files.

`README_AI.md` defines the required naming conventions, folder structure, domain mapping approach, testing approach, spy conventions, and output format expected for projects built on top of this framework.

In particular, it explains that:

- endpoint configuration must use `*Setup`
- request executors must use `*Provider`
- AI-generated integrations should create a `Domain` folder with feature protocols and models
- providers should conform to the Domain protocol when that architecture is used
- API responses should map into Domain models through a `domain` computed property
- tests must reuse the same production `Provider`
- JSON-backed testing should use `MockedURLSession`
- concrete spies and service-level spy aggregators are handwritten by the consumer
- the final generated result must preserve the host project structure and be deliverable as a zip file

`iOSCleanNetwork` can be used in two different ways:

1. **AI-assisted generation**
2. **Manual implementation**

For most consumers, the intended workflow is to use **AI first**.

Give an AI agent:

- the URL of this repository
- the endpoint documentation URL, OpenAPI spec, or endpoint description
- one or more sample JSON responses, if available

The repository includes a dedicated [`README_AI.md`](./README_AI.md) file for AI agents. That file explains how code must be generated when building on top of this framework.

The goal is that an AI agent can inspect this repository, find `README_AI.md`, and generate all the human-written integration files needed to consume a service with `iOSCleanNetwork`.

## AI-first use case

If you want to accelerate implementation, the preferred flow is:

1. Give the AI this repository URL
2. Give the AI the endpoint documentation and, if possible, the expected JSON responses
3. Let the AI generate the integration code following this framework's conventions
4. Review the generated output with this README if you want to understand how it was structured

This human README is therefore useful for **two things**:

- understanding how the framework works if you want to code by hand
- understanding what an AI agent generated if the code was produced automatically

## What the AI is expected to generate

When an AI agent follows [`README_AI.md`](./README_AI.md), it should generate the files that a human would normally write to integrate a service with this framework.

That usually includes:

- one or more `*Setup` types conforming to `ApiSetupProtocol`
- one or more `*Provider` types that perform the request and decode the response
- a `Domain` folder with feature protocols and domain models when the project uses that architecture
- request payload models using the `*DTO` naming
- transport response models using the `*Response` naming
- response-to-domain mappers declared as a `domain` computed property
- JSON fixtures for testing
- tests using the same production `Provider`
- concrete provider spies written by hand on top of `ProviderSpyProtocol`
- optional service-level spy aggregators written by hand by the consumer
- the expected folder structure matching the host project layout

The generated output should be ready to drop into a real project and should follow the same conventions documented below in this README.

## How to use what the AI generated

After the AI generates the integration code, you typically:

1. add the generated Swift and JSON files to your host project
2. verify that the folders match your project structure
3. review the generated Domain models, `Setup`, `Provider`, DTOs, responses, mappers, fixtures, and tests
4. run the tests
5. wire the generated provider or Domain protocol into your app or SDK

You can use the rest of this README to understand:

- why the generated files were named that way
- what each generated file is responsible for
- how runtime and testing are expected to work

## If you want to build it by hand

If you do not want to use AI generation, the rest of this README explains the conventions, structure, and testing approach required to build the integration manually.

## Optional Domain layer recommendation

A common architecture is to expose a protocol from the Domain layer and make the Data provider conform to it.

When you do that, prefer naming the protocol after the **feature it provides**, not after the raw API name.

Examples:

- the API may be **Apigee**
- the Domain protocol may be `AgiGatewayProtocol`
- or it may be `SessionManagerProtocol`

Other examples:

- `PaymentsProtocol`
- `ProfileGatewayProtocol`
- `UserSessionProtocol`

That naming is optional and depends on the project architecture. If your project is simpler, you can skip the extra Domain abstraction. But when a Domain layer exists, it is usually better for the protocol to describe the feature or capability rather than the transport source.

## For AI agents

If you are an AI agent generating code from this repository, read [`README_AI.md`](./README_AI.md) before writing any files.

`README_AI.md` defines the required naming conventions, folder structure, domain mapping approach, testing approach, spy conventions, and output format expected for projects built on top of this framework.

In particular, it explains that:

- endpoint configuration must use `*Setup`
- request executors must use `*Provider`
- AI-generated integrations should create a `Domain` folder with feature protocols and models
- providers should conform to the Domain protocol when that architecture is used
- API responses should map into Domain models through a `domain` computed property
- tests must reuse the same production `Provider`
- JSON-backed testing should use `MockedURLSession`
- concrete spies and service-level spy aggregators are handwritten by the consumer
- the final generated result must preserve the host project structure and be deliverable as a zip file

`iOSCleanNetwork` is a lightweight Swift Package for building API clients with a clear and predictable structure.

The package is based on two simple conventions:

- types ending in **`Setup`** define endpoint configuration
- types ending in **`Provider`** execute the request and decode the response

When a project uses a Domain layer, the expected split is:

- **Domain** exposes feature protocols and domain models
- **Data** contains the transport-specific `Setup`, `Provider`, DTOs, responses, and response mappers
- **Provider** decodes transport responses and returns Domain models

It also keeps the transport layer abstract through `NetworkSessionProtocol`, so tests do not require mocking the Provider at all. You can keep the exact same production Provider, inject `MockedURLSession`, provide the expected JSON fixtures, and let the same decoding and mapping flow used in production return the final Domain model.

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
- mapping transport responses into Domain models when the project uses a Domain layer
- returning the final model expected by the feature

Examples:

- `GitHubUserAPIProvider`
- `StripeAPIProvider`
- `SpotifyAPIProvider`

### Domain protocols

When a Domain layer exists, define the protocol in the Domain layer and make the Data provider conform to it.

Prefer protocol names that describe the feature instead of the API vendor or API product name.

Good examples:

- `PaymentsProtocol`
- `SessionManagerProtocol`
- `AgiGatewayProtocol`

Less desirable in a Domain layer:

- `StripeAPIProviding`
- `ApigeeAPIProviding`

This is not mandatory for every project. It is an architectural option. But if you introduce the Domain layer, keep the protocol aligned with the feature.

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

## Domain model mapping

If your project uses a Domain layer, do the mapping in the Data layer.

A common structure is:

- `Domain/Protocols/`
- `Domain/Models/`
- `Data/APIs/.../RequestsDTOs/`
- `Data/APIs/.../Responses/`

Each transport response can expose a `domain` computed property that maps it into the corresponding Domain model.

Example:

```swift
import Foundation

struct PaymentIntent: Equatable {
    let identifier: String
    let status: String
    let clientSecret: String?
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

extension StripePaymentIntentResponse {
    // MARK: - Domain Mapper

    var domain: PaymentIntent {
        PaymentIntent(
            identifier: id,
            status: status,
            clientSecret: clientSecret
        )
    }
}
```

That keeps:

- transport details in Data
- presenter-facing types in Domain
- mapping close to the API response that owns the transport shape

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

This example shows a common setup in a single module:

- one `GET` endpoint without body
- one `POST` endpoint with body
- one `Setup`
- one `Provider`
- one Domain protocol
- one Domain model
- one transport response mapper

### 1. Define the Domain model and Domain protocol

```swift
import Foundation

struct PaymentIntent: Equatable {
    let identifier: String
    let status: String
    let clientSecret: String?
}

protocol PaymentsProtocol {
    func retrievePaymentIntent(
        secretAPIKey: String,
        paymentIntentID: String
    ) async throws -> PaymentIntent

    func createPaymentIntent(
        secretAPIKey: String,
        paymentIntentDTO: CreatePaymentIntentDTO
    ) async throws -> PaymentIntent
}
```

### 2. Define request DTOs and response models

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

extension StripePaymentIntentResponse {
    // MARK: - Domain Mapper

    var domain: PaymentIntent {
        PaymentIntent(
            identifier: id,
            status: status,
            clientSecret: clientSecret
        )
    }
}
```

### 3. Define a `Setup`

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

### 4. Define a `Provider`

```swift
import Foundation
import iOSCleanNetwork

final class StripeAPIProvider: PaymentsProtocol {
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
    ) async throws -> PaymentIntent {
        let setup = StripeAPISetup.retrievePaymentIntent(
            baseURL: baseURL,
            secretAPIKey: secretAPIKey,
            paymentIntentID: paymentIntentID
        )

        let (data, _) = try await session.data(for: setup)
        let response = try JSONDecoder().decode(StripePaymentIntentResponse.self, from: data)
        return response.domain
    }

    func createPaymentIntent(
        secretAPIKey: String,
        paymentIntentDTO: CreatePaymentIntentDTO
    ) async throws -> PaymentIntent {
        let setup = StripeAPISetup.createPaymentIntent(
            baseURL: baseURL,
            secretAPIKey: secretAPIKey,
            paymentIntentDTO: paymentIntentDTO
        )

        let (data, _) = try await session.data(for: setup)
        let response = try JSONDecoder().decode(StripePaymentIntentResponse.self, from: data)
        return response.domain
    }
}
```

### 5. Use the `Provider`

```swift
import Foundation

let provider: PaymentsProtocol = StripeAPIProvider(
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

- `StripeAPISetup` contains endpoint configuration
- `StripeAPIProvider` contains request execution
- `PaymentsProtocol` expresses the feature contract
- `StripePaymentIntentResponse` stays in the Data layer
- `PaymentIntent` is the model returned to the feature or presenter
- the mapper lives next to the transport response

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

### Example provider using refresh retry and Domain mapping

```swift
import Foundation
import iOSCleanNetwork

struct UserProfile {
    let identifier: String
    let displayName: String
}

protocol ProfileGatewayProtocol {
    func fetchProfile() async throws -> UserProfile
}

struct SpotifyProfileResponse: Decodable {
    let id: String
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
    }
}

extension SpotifyProfileResponse {
    // MARK: - Domain Mapper

    var domain: UserProfile {
        UserProfile(
            identifier: id,
            displayName: displayName
        )
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

final class SpotifyAPIProvider: ProfileGatewayProtocol {
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

    func fetchProfile() async throws -> UserProfile {
        let (data, _) = try await session.dataWithUnauthorizedRefreshRetry(
            apiAccessProvider: apiAccessProvider,
            buildEndpoint: { accessToken in
                SpotifyAPISetup.profile(
                    baseURL: self.baseURL,
                    accessToken: accessToken
                )
            }
        )

        let response = try JSONDecoder().decode(SpotifyProfileResponse.self, from: data)
        return response.domain
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
- same mapping logic
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
6. the same Provider decodes that data
7. the same Provider maps the response to Domain if needed
8. the same Provider returns the final model

That means you do **not** need to rewrite the Provider for testing.

## Example test

```swift
import Testing
import Foundation
import iOSCleanNetwork
import iOSCleanNetworkTesting

struct GitHubUserAPIProviderTests {
    @Test
    func fetchUser_returnsMappedDomainFixture() async throws {
        // Given
        let baseURL = URL(string: "https://api.github.com")!
        let session = MockedURLSession()
        let provider = GitHubUserAPIProvider(
            baseURL: baseURL,
            session: session
        )

        // When
        let actual = try await provider.fetchUser(username: "octocat")

        // Then
        #expect(actual.login == "octocat")
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

For each provider or Domain protocol you want to observe in tests, you usually write one spy manually.

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

final class PaymentsProviderSpy: ProviderSpyProtocol {
    enum MethodKey: String, Hashable, CaseIterable {
        case retrievePaymentIntent
        case createPaymentIntent
    }

    var invocationsCount: [MethodKey: Int] = [:]
    var failingMethos: [(method: MethodKey, error: Error)] = []

    private let wrappedProvider: any PaymentsProtocol

    init(wrapping wrappedProvider: any PaymentsProtocol) {
        self.wrappedProvider = wrappedProvider
    }
}

extension PaymentsProviderSpy: PaymentsProtocol {
    func retrievePaymentIntent(
        secretAPIKey: String,
        paymentIntentID: String
    ) async throws -> PaymentIntent {
        increment(.retrievePaymentIntent)
        try validateFailingMethods(method: .retrievePaymentIntent)
        return try await wrappedProvider.retrievePaymentIntent(
            secretAPIKey: secretAPIKey,
            paymentIntentID: paymentIntentID
        )
    }

    func createPaymentIntent(
        secretAPIKey: String,
        paymentIntentDTO: CreatePaymentIntentDTO
    ) async throws -> PaymentIntent {
        increment(.createPaymentIntent)
        try validateFailingMethods(method: .createPaymentIntent)
        return try await wrappedProvider.createPaymentIntent(
            secretAPIKey: secretAPIKey,
            paymentIntentDTO: paymentIntentDTO
        )
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

final class CheckoutFlowServiceSpy: CheckoutFlowService {
    private let paymentsProviderSpy: PaymentsProviderSpy
    private let authGatewayProviderSpy: AuthGatewayProviderSpy

    init(
        paymentsProvider: any PaymentsProtocol,
        authGatewayProvider: any AuthGatewayProtocol
    ) {
        self.paymentsProviderSpy = PaymentsProviderSpy(wrapping: paymentsProvider)
        self.authGatewayProviderSpy = AuthGatewayProviderSpy(wrapping: authGatewayProvider)

        super.init(
            paymentsProvider: paymentsProviderSpy,
            authGatewayProvider: authGatewayProviderSpy
        )
    }
}
```

### Aggregate invocation assertions

```swift
import Testing

extension CheckoutFlowServiceSpy {
    enum MethodsKeys {
        case payments([(PaymentsProviderSpy.MethodKey, Int)])
        case authGateway([(AuthGatewayProviderSpy.MethodKey, Int)])

        static func payments(_ keys: PaymentsProviderSpy.MethodKey...) -> Self {
            .payments(keys.map { ($0, 1) })
        }

        static func payments(_ items: (PaymentsProviderSpy.MethodKey, times: Int)...) -> Self {
            .payments(items.map { ($0.0, $0.times) })
        }

        static func authGateway(_ keys: AuthGatewayProviderSpy.MethodKey...) -> Self {
            .authGateway(keys.map { ($0, 1) })
        }

        static func authGateway(_ items: (AuthGatewayProviderSpy.MethodKey, times: Int)...) -> Self {
            .authGateway(items.map { ($0.0, $0.times) })
        }
    }

    func assertExpectedInvocations(
        _ expectedCalls: MethodsKeys...,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        enum Provider: CaseIterable {
            case payments
            case authGateway
        }

        var seenProviders = Set<Provider>()

        for expectedCall in expectedCalls {
            switch expectedCall {
            case .payments(let expected):
                seenProviders.insert(.payments)
                paymentsProviderSpy.assertExpectedInvocations(expected, sourceLocation: sourceLocation)

            case .authGateway(let expected):
                seenProviders.insert(.authGateway)
                authGatewayProviderSpy.assertExpectedInvocations(expected, sourceLocation: sourceLocation)
            }
        }

        for provider in Provider.allCases where seenProviders.contains(provider) == false {
            switch provider {
            case .payments:
                paymentsProviderSpy.assertExpectedInvocations([], sourceLocation: sourceLocation)
            case .authGateway:
                authGatewayProviderSpy.assertExpectedInvocations([], sourceLocation: sourceLocation)
            }
        }
    }

    func resetAllCounters() {
        paymentsProviderSpy.resetInvocationsCount()
        authGatewayProviderSpy.resetInvocationsCount()
    }
}
```

### Aggregate failure injection

```swift
import Foundation

extension CheckoutFlowServiceSpy {
    enum FailingMethods {
        case payments([(PaymentsProviderSpy.MethodKey, Error)])
        case authGateway([(AuthGatewayProviderSpy.MethodKey, Error)])

        static func payments(
            _ keys: PaymentsProviderSpy.MethodKey...,
            error: Error = CheckoutFlowServiceSpyError.forcedFailure
        ) -> Self {
            .payments(keys.map { ($0, error) })
        }

        static func authGateway(
            _ keys: AuthGatewayProviderSpy.MethodKey...,
            error: Error = CheckoutFlowServiceSpyError.forcedFailure
        ) -> Self {
            .authGateway(keys.map { ($0, error) })
        }
    }

    func failingMethods(_ failingMethods: FailingMethods...) {
        for failingMethod in failingMethods {
            switch failingMethod {
            case .payments(let methods):
                paymentsProviderSpy.failingMethods(methods)
            case .authGateway(let methods):
                authGatewayProviderSpy.failingMethods(methods)
            }
        }
    }
}

private enum CheckoutFlowServiceSpyError: Error {
    case forcedFailure
}
```

## Example tests using the service-level spy

The end goal of the service-level spy is test ergonomics.

Instead of checking every wrapped spy manually, tests stay short and readable.

```swift
import Testing

struct CheckoutFlowServiceTests {
    @Test
    func loadPayment_succeeds() async throws {
        // Given
        let service = CheckoutFlowServiceSpy(
            paymentsProvider: StubPaymentsProvider.success,
            authGatewayProvider: StubAuthGatewayProvider.success
        )
        service.resetAllCounters()

        // When
        let actual = try await service.loadPayment()

        // Then
        #expect(actual.identifier == "pi_123")
        service.assertExpectedInvocations(
            .authGateway(.accessToken),
            .payments(.retrievePaymentIntent)
        )
    }

    @Test
    func loadPayment_throwsWhenRequestFails() async throws {
        // Given
        let service = CheckoutFlowServiceSpy(
            paymentsProvider: StubPaymentsProvider.success,
            authGatewayProvider: StubAuthGatewayProvider.success
        )
        service.resetAllCounters()
        service.failingMethods(.payments(.retrievePaymentIntent))

        // When
        do {
            _ = try await service.loadPayment()
            Issue.record("Expected loadPayment to throw forcedFailure")
        } catch {
            // Then
            #expect(error is CheckoutFlowServiceSpyError)
            service.assertExpectedInvocations(
                .authGateway(.accessToken),
                .payments(.retrievePaymentIntent)
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
- a Domain protocol can express the feature contract
- transport responses can map to Domain models through a `domain` computed property
- the session is injected
- authentication remains external through `ApisGatewayProtocol`
- in tests, the same `Provider` can run unchanged by swapping the session for `MockedURLSession`

That keeps both production and test code simple, explicit, and easy to maintain.
