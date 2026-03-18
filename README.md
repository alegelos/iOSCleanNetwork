# iOSCleanNetwork

A small Swift Package that keeps networking explicit, lightweight, and easy to test.

It ships with two library products:

- **`iOSCleanNetwork`**: the runtime networking layer
- **`iOSCleanNetworkTesting`**: test helpers for mocked sessions, JSON fixtures, and provider spies

The package is intentionally minimal. You define your own endpoints, providers, and models, while the package gives you the common building blocks to execute requests, validate responses, and make tests simpler.

## Requirements

- Swift Package Manager
- Swift tools version: `6.2`
- iOS `17+`
- macOS `12+`

## Products

### `iOSCleanNetwork`
Use this in production code.

It includes:

- `ApiSetupProtocol`
- `ApiProvider`
- `NetworkSessionProtocol`
- `ApisGatewayProtocol`
- `AccessTokenPolicy`
- `ApiErrors`
- `URLSession` conformance to `NetworkSessionProtocol`
- shared response validation

### `iOSCleanNetworkTesting`
Use this in test targets.

It includes:

- `MockedURLSession`
- `URLSessionSetupProtocol`
- `JSonReader`
- `ProviderSpyProtocol`

## Installation

Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/your-org/iOSCleanNetwork.git", from: "1.0.0")
```

Then add the products you need:

```swift
.target(
    name: "SampleFeature",
    dependencies: [
        .product(name: "iOSCleanNetwork", package: "iOSCleanNetwork")
    ]
),
.testTarget(
    name: "SampleFeatureTests",
    dependencies: [
        "SampleFeature",
        .product(name: "iOSCleanNetworkTesting", package: "iOSCleanNetwork")
    ]
)
```

## Overview

The typical flow looks like this:

1. Define an endpoint that conforms to `ApiSetupProtocol`
2. Create a provider that conforms to `ApiProvider`
3. Use `URLSession` in production
4. Use `MockedURLSession` in tests
5. Optionally use `ProviderSpyProtocol` to verify method calls and planned failures

---

## Basic runtime usage

### 1. Define a model

```swift
import Foundation

struct SampleItem: Decodable, Equatable {
    let identifier: Int
    let title: String
}
```

### 2. Define an endpoint

```swift
import Foundation
import iOSCleanNetwork

enum SampleItemsEndpoint: ApiSetupProtocol {
    case list(baseURL: URL)

    var request: URLRequest {
        get throws {
            var components = URLComponents(
                url: baseURL.appendingPathComponent(path),
                resolvingAgainstBaseURL: false
            )
            components?.queryItems = queryItems

            guard let url = components?.url else {
                throw ApiErrors.invalidUrl
            }

            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = method.rawValue
            urlRequest.httpBody = body

            try headers.forEach { headerField, value in
                urlRequest.setValue(value, forHTTPHeaderField: headerField)
            }

            return urlRequest
        }
    }

    var path: String {
        switch self {
        case .list:
            return "items"
        }
    }

    var method: HttpMethod {
        .get
    }

    var headers: [String: String] {
        get throws {
            ["Accept": "application/json"]
        }
    }

    var body: Data? {
        nil
    }

    var queryItems: [URLQueryItem] {
        []
    }

    private var baseURL: URL {
        switch self {
        case let .list(baseURL):
            return baseURL
        }
    }
}
```

### 3. Define a provider

```swift
import Foundation
import iOSCleanNetwork

final class SampleItemsProvider: ApiProvider {
    let baseURL: URL
    let session: NetworkSessionProtocol

    init(
        baseURL: URL,
        session: NetworkSessionProtocol = URLSession.shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchItems() async throws -> [SampleItem] {
        let endpoint = SampleItemsEndpoint.list(baseURL: baseURL)
        let (data, _) = try await session.data(for: endpoint)
        return try JSONDecoder().decode([SampleItem].self, from: data)
    }
}
```

### 4. Call the provider

```swift
let provider = SampleItemsProvider(
    baseURL: URL(string: "https://api.example.com")!
)

let items = try await provider.fetchItems()
```

---

## Protected endpoints with automatic refresh retry

If an endpoint requires an access token, the package also provides a retry flow for `401 Unauthorized` responses.

### 1. Define an access gateway

```swift
import Foundation
import iOSCleanNetwork

final class SampleAccessGateway: ApisGatewayProtocol {
    func apisAccessToken(policy: AccessTokenPolicy) async throws -> String {
        switch policy {
        case .useCache:
            return "cached-token"
        case .forceRefresh:
            return "fresh-token"
        }
    }
}
```

### 2. Build the endpoint with the token

```swift
import Foundation
import iOSCleanNetwork

enum SampleProfileEndpoint: ApiSetupProtocol {
    case profile(baseURL: URL, accessToken: String)

    var request: URLRequest {
        get throws {
            let url = baseURL.appendingPathComponent(path)
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = method.rawValue

            try headers.forEach { headerField, value in
                urlRequest.setValue(value, forHTTPHeaderField: headerField)
            }

            return urlRequest
        }
    }

    var path: String { "profile" }
    var method: HttpMethod { .get }
    var body: Data? { nil }
    var queryItems: [URLQueryItem] { [] }

    var headers: [String: String] {
        get throws {
            [
                "Accept": "application/json",
                "Authorization": "Bearer \(accessToken)"
            ]
        }
    }

    private var baseURL: URL {
        switch self {
        case let .profile(baseURL, _):
            return baseURL
        }
    }

    private var accessToken: String {
        switch self {
        case let .profile(_, accessToken):
            return accessToken
        }
    }
}
```

### 3. Execute with retry support

```swift
let gateway = SampleAccessGateway()
let session = URLSession.shared
let baseURL = URL(string: "https://api.example.com")!

let (data, _) = try await session.dataWithUnauthorizedRefreshRetry(
    apiAccessProvider: gateway,
    buildEndpoint: { accessToken in
        SampleProfileEndpoint.profile(baseURL: baseURL, accessToken: accessToken)
    }
)
```

If the first request throws `ApiErrors.unauthorized`, the package requests a fresh token with `.forceRefresh` and retries once.

---

## Testing with `MockedURLSession`

`MockedURLSession` lets your tests return local JSON instead of performing a real HTTP request.

### 1. Make your endpoint test-aware

```swift
import Foundation
import iOSCleanNetworkTesting

extension SampleItemsEndpoint: URLSessionSetupProtocol {
    var jsonFileName: String {
        switch self {
        case .list:
            return "sample-items"
        }
    }
}
```

### 2. Use `MockedURLSession` in your provider

```swift
import Foundation
import iOSCleanNetwork
import iOSCleanNetworkTesting

let provider = SampleItemsProvider(
    baseURL: URL(string: "https://api.example.com")!,
    session: MockedURLSession()
)

let items = try await provider.fetchItems()
```

### 3. Add a JSON fixture

Create a JSON file for the mocked response:

```json
[
  {
    "identifier": 1,
    "title": "First item"
  },
  {
    "identifier": 2,
    "title": "Second item"
  }
]
```

And map the endpoint to that fixture with `jsonFileName`.

---

## Testing with `ProviderSpyProtocol`

`ProviderSpyProtocol` is useful when you want to verify:

- how many times each method was called
- whether a method should fail on demand
- whether unexpected methods were called

### Example: `SampleProviderSpy`

```swift
import Foundation
import iOSCleanNetworkTesting

protocol SampleProviderProtocol {
    func fetchItems() async throws -> [SampleItem]
    func updateItem(title: String) async throws
}

final class SampleProviderSpy: ProviderSpyProtocol {
    var invocationsCount: [MethodKey: Int] = [:]
    var failingMethos: [(method: MethodKey, error: Error)] = []

    private let wrappedProvider: SampleProviderProtocol

    init(wrapping wrappedProvider: SampleProviderProtocol) {
        self.wrappedProvider = wrappedProvider
    }

    enum MethodKey: String, Hashable, CaseIterable {
        case fetchItems
        case updateItem
    }
}

extension SampleProviderSpy: SampleProviderProtocol {
    func fetchItems() async throws -> [SampleItem] {
        increment(.fetchItems)
        try validateFailingMethods(method: .fetchItems)
        return try await wrappedProvider.fetchItems()
    }

    func updateItem(title: String) async throws {
        increment(.updateItem)
        try validateFailingMethods(method: .updateItem)
        try await wrappedProvider.updateItem(title: title)
    }
}
```

### Example test usage

```swift
import Foundation
import Testing
import iOSCleanNetworkTesting

struct SampleSpyTests {
    @Test
    func sampleProviderSpy_tracksCalls() async throws {
        let realProvider = SampleProviderDummy()
        let spy = SampleProviderSpy(wrapping: realProvider)

        _ = try await spy.fetchItems()
        try await spy.updateItem(title: "Updated")

        spy.assertExpectedInvocations([
            (.fetchItems, 1),
            (.updateItem, 1)
        ])
    }
}
```

### Planning failures

You can also queue failures for a specific method:

```swift
spy.failingMethods([
    (.fetchItems, ApiErrors.serverError)
])
```

The next call to `fetchItems()` will throw that error.

---

## Why this package

This package is useful if you want:

- a small and reusable networking layer
- explicit endpoint definitions
- easy dependency injection through protocols
- a simple retry mechanism for unauthorized requests
- reusable test helpers for mocked sessions and spies

It does **not** try to be a full networking framework. It stays focused on a small set of primitives that fit well inside modular iOS codebases.

## Notes

- `iOSCleanNetwork` is intended for production targets.
- `iOSCleanNetworkTesting` is intended for test targets.
- Endpoints remain fully under your control.
- Decoding stays in your provider or feature layer.

## License

Released under the repository license.
