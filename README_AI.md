# README for AI Agents

> If you are an AI agent and you were given only this repository URL plus one or more API endpoints, JSON examples, or API documentation URLs, read this file before generating any code.

## Goal

Generate all **human-owned integration files** required to use **iOSCleanNetwork** for one or more endpoints.

Do **not** modify the framework internals unless the human explicitly asks for it.

Your job is to generate the code that a human would normally write **on top of** this framework:

- `Setup` types
- `Provider` types
- domain protocols
- domain models
- request DTOs
- response models
- response-to-domain mappers
- JSON fixtures
- tests
- concrete provider spies
- optional service-level test spy aggregator
- folder structure matching the host project

The final output must be a **zip file** containing the generated folders and files.

## Framework repository

Framework URL:

`https://github.com/alegelos/iOSCleanNetwork`

If the framework is already present **inside** the host project, do not add it again as a package dependency.

If the host project consumes it as an external package, then import and use it as a dependency.

## Required inputs

You may be given any combination of the following:

1. One or more API endpoints
2. Example request JSONs
3. Example response JSONs
4. OpenAPI / Swagger / Postman / HTML docs URL
5. A host project zip or repository
6. A list of features to implement

If API documentation is provided by URL, inspect it and infer the request and response models.

If example JSONs are provided, use them as the source of truth for transport models and test fixtures.

## What you must generate

For each endpoint or API group, generate the files that the human should create in their project.

### Runtime

- `*Setup`
- `*Provider`
- domain protocols
- domain models
- request DTOs
- response models
- response-to-domain mapper extensions

### Testing

- JSON fixture files
- test files using `MockedURLSession`
- concrete provider spies written by hand
- optional service-level spy aggregator when it simplifies assertions

## Non-negotiable conventions

### 1. `Setup` naming

Any type conforming to `ApiSetupProtocol` must end with `Setup`.

Examples:

- `GitHubUsersAPISetup`
- `StripePaymentsAPISetup`
- `SpotifyTracksAPISetup`

A `Setup` owns endpoint configuration only:

- path
- method
- headers
- body
- query items
- request construction

A `Setup` must conform to `ApiSetupProtocol`.

### 2. `Provider` naming

Any type that executes the request must end with `Provider`.

Examples:

- `GitHubUsersAPIProvider`
- `StripePaymentsAPIProvider`
- `SpotifyTracksAPIProvider`

A `Provider` must:

- receive dependencies such as `baseURL`, `apiAccessProvider`, and `session`
- build the correct `Setup`
- perform the request
- decode the transport response
- map the decoded transport response into domain models
- return the mapped domain result
- conform to the feature protocol declared in the Domain layer when a domain protocol exists

### 3. Domain protocol naming

When generating a Domain protocol, name it after the **feature or capability**, not after the raw API name.

Prefer names such as:

- `AgiGatewayProtocol`
- `SessionManagerProtocol`
- `PaymentsProtocol`
- `ProfileGatewayProtocol`

Avoid transport-driven protocol names such as:

- `ApigeeAPIProviding`
- `StripeAPIProviding`
- `SpotifyAPIProviding`

This is optional and depends on the host project architecture, but when you generate a Domain layer by default, the protocol belongs to the Domain layer and should describe what the feature provides.

### 4. Transport model naming

Use these naming conventions:

- API responses: `*Response`
- request payload models / request parameters: `*DTO`

Examples:

- `CreatePaymentIntentDTO`
- `GitHubUserResponse`
- `SpotifyTrackResponse`

### 5. Domain model generation

Generate a Domain folder with:

- `Protocols/`
- `Models/`

Rules:

- Domain protocols live in `Domain/Protocols/`
- Domain models live in `Domain/Models/`
- Presenter-facing and feature-facing return types must be domain models, not transport responses
- Data providers must conform to the domain protocol when one is generated
- If an endpoint does not need a separate domain model because the project explicitly wants to use the transport response directly, only do that when the human asks for it

### 6. Domain mapping in response models

For each API response model that maps into the Domain layer, add an extension in the Data layer.

Use this exact style:

```swift
extension ExampleResponse {
    // MARK: - Domain Mapper

    var domain: ExampleDomainModel {
        ExampleDomainModel(
            ...
        )
    }
}
```

Rules:

- the mapper must live in the Data layer
- the computed property must be named `domain`
- the property must return the corresponding domain model
- providers must call `.domain` before returning values through the domain protocol
- arrays of responses must be mapped into arrays of domain models before returning

### 7. Testing with JSON fixtures

Do **not** rewrite the production `Provider` for tests.

The same `Provider` used in production must also be used in tests.

Testing must work by:

- injecting `MockedURLSession`
- providing JSON fixture files
- keeping the same decoding logic as production
- keeping the same domain mapping as production when the provider returns domain models

That means:

- no special test-only provider implementation
- no duplicated request logic
- no manual fake decoding flow

Only the session changes.

### 8. `URLSessionSetupProtocol` for fixtures

If a `Setup` must be used with `MockedURLSession`, extend it to conform to `URLSessionSetupProtocol` and provide `jsonFileName`.

### 9. Spies

The framework provides the reusable protocol:

- `ProviderSpyProtocol`

The following are **not** generated by the framework and must be handwritten per project by the user or by you, the AI agent:

- concrete provider spies
- optional service-level spy aggregator
- tests using those spies

## How spies must be generated

### Provider-level spies

For each protocol that the human wants to observe, generate a handwritten spy wrapping the real implementation.

If a Domain protocol exists, the spy should normally wrap that Domain protocol.

Pattern:

- conform to `ProviderSpyProtocol`
- define `MethodKey`
- store `invocationsCount`
- store `failingMethos`
- wrap the real service
- in each method:
  - call `increment(...)`
  - call `try validateFailingMethods(method: ...)`
  - forward to the wrapped implementation

### Service-level aggregator spy

When the feature involves multiple providers and tests would be noisy, generate a handwritten service-level spy aggregator.

That aggregator should:

- own multiple concrete provider spies
- expose `resetAllCounters()`
- expose `failingMethods(...)`
- expose `assertExpectedInvocations(...)`
- make tests short and readable

This aggregator is project-specific and must be handwritten too.

## Test style

Always write tests with:

- `Given`
- `When`
- `Then`

Keep tests short.

Prefer a style where the final assertions are concise, for example:

```swift
try service.assertExpectedInvocations(
    .user(.fetchProfile),
    .session((.renewToken, times: 2))
)
```

Prefer `expected` and `actual` naming when direct value assertions are needed.

## Folder structure

You must inspect the host project and follow its structure.

Do not invent a random layout if the project already has a clear convention.

### If the project already exists

Mirror the existing structure.

For example, if the project groups files like this:

```text
Feature/
├─ Domain/
│  ├─ Protocols/
│  │  └─ PaymentsProtocol.swift
│  └─ Models/
│     └─ PaymentIntent.swift
├─ Data/
│  ├─ APIs/
│  │  ├─ ExampleAPI/
│  │  │  ├─ RequestsDTOs/
│  │  │  ├─ Responses/
│  │  │  ├─ ExampleAPISetup.swift
│  │  │  └─ ExampleAPIProvider.swift
Tests/
├─ FeatureTests/
│  ├─ Data/
│  │  ├─ APIs/
│  │  │  ├─ ExampleAPI/
│  │  │  │  ├─ Jsons/
│  │  │  │  ├─ ExampleAPISetup+Json.swift
│  │  │  │  ├─ ExampleAPIProviderTests.swift
│  │  │  │  └─ ExampleAPIProviderSpy.swift
```

follow that pattern.

### If no structure exists yet

Generate this default layout:

```text
Feature/
├─ Domain/
│  ├─ Protocols/
│  │  └─ ExampleFeatureProtocol.swift
│  └─ Models/
│     └─ ExampleFeatureModel.swift
├─ Data/
│  ├─ APIs/
│  │  ├─ ExampleAPI/
│  │  │  ├─ RequestsDTOs/
│  │  │  ├─ Responses/
│  │  │  ├─ ExampleAPISetup.swift
│  │  │  └─ ExampleAPIProvider.swift
Tests/
├─ FeatureTests/
│  ├─ Data/
│  │  ├─ APIs/
│  │  │  ├─ ExampleAPI/
│  │  │  │  ├─ Jsons/
│  │  │  │  ├─ ExampleAPISetup+Json.swift
│  │  │  │  ├─ ExampleAPIProviderTests.swift
│  │  │  │  ├─ ExampleAPIProviderSpy.swift
│  │  │  │  └─ FeatureServiceProviderSpy.swift
```

## Multi-endpoint rule

If the human gives you multiple endpoints for the same API area, prefer a single `Setup` and a single `Provider` when that matches the project style.

Example:

- one `GET`
- one `POST`
- same API group
- same `Provider`
- same `Setup` enum with multiple cases

This is preferred over splitting everything into many tiny files unless the host project already does that.

## Production example shape

The generated code should follow this shape:

### `Setup`

- conform directly to `ApiSetupProtocol`
- support one or many cases
- expose `request`
- centralize `path`, `method`, `headers`, `body`, `queryItems`

### Domain protocol

- live in the Domain layer
- describe the feature, not the transport source
- return domain models

### Domain models

- live in `Domain/Models`
- be used by the presenter layer
- stay transport-agnostic

### `Provider`

- live in the Data layer
- inject `baseURL`
- inject `session: any NetworkSessionProtocol`
- inject `apiAccessProvider` only when needed
- conform to the domain protocol when one exists
- call `session.data(for:)` or `session.dataWithUnauthorizedRefreshRetry(...)`
- decode using `JSONDecoder`
- map decoded `*Response` values into domain models via `.domain`
- return domain models

## Production example

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

## Testing example shape

### JSON-backed tests

- same production `Provider`
- inject `MockedURLSession`
- extend `Setup` with `URLSessionSetupProtocol`
- provide one JSON file per scenario when needed
- assert against the returned domain model when the provider exposes domain models

### Spy-backed tests

Generate handwritten concrete spies only when the feature benefits from call counting or injected failures.

Do not pretend the framework auto-generates those spies.

## Output contract

Your final answer must produce a **zip file** containing all generated files.

The zip must include:

- folders
- Swift files
- JSON fixture files
- tests
- spies

Also include a short manifest in the answer listing the generated paths.

## What not to do

Do not:

- modify framework internals
- rename framework protocols
- replace `Setup` with another naming convention
- replace `Provider` with another naming convention
- expose raw `*Response` transport models to the presenter layer when a domain model was generated
- create a separate fake provider for tests when `MockedURLSession` is enough
- claim spies are framework-generated when they are handwritten
- name the domain protocol after the API brand when the feature can be named more clearly

## Decision process for the AI agent

When given the repository URL plus endpoint information, do this:

1. Open this repository
2. Read `README.md`
3. Read `README_AI.md`
4. Inspect the host project structure if provided
5. Infer request DTOs and response models from docs or JSONs
6. Generate the Domain protocol in `Domain/Protocols`
7. Generate domain models in `Domain/Models`
8. Generate `Setup` and `Provider`
9. Generate response-to-domain mappers with a `domain` computed property
10. Make the Data provider conform to the Domain protocol and return domain models
11. Generate `Setup+Json` test extension if needed
12. Generate JSON fixtures
13. Generate tests using `MockedURLSession`
14. Generate handwritten concrete spies when requested or useful
15. Generate a handwritten service-level aggregator spy if it simplifies tests
16. Package all generated files as a zip

## Short instruction block for AI agents

If you need a compact execution summary, follow this exactly:

- Use `*Setup` for anything conforming to `ApiSetupProtocol`
- Use `*Provider` for anything executing the request
- Use `*DTO` for request payload models
- Use `*Response` for API response models
- Generate `Domain/Protocols` and `Domain/Models`
- Name domain protocols after the feature, not the API brand
- Make the Data provider conform to the Domain protocol
- Add a `domain` computed property mapper on each response that maps to a domain model
- Return domain models from the provider
- Reuse the same production `Provider` in tests
- Test by injecting `MockedURLSession` and JSON fixtures
- Write concrete spies by hand using `ProviderSpyProtocol`
- Write optional service-level spy aggregators by hand
- Follow the host project folder structure
- Return the final output as a zip file
