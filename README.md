# iOSCleanNetwork

A small Swift networking SDK for applications that keep endpoint configuration,
transport models and domain models separate. Use the same provider with a real
session in production and JSON fixtures in tests.

Requires **Swift 6.2+** and **iOS 15+**. All examples use fictional users and
`example.com`; they do not call a working service.

## Start here

- **Integrating with an AI agent:** install the
  [CleanNetwork plugin](https://github.com/alegelos/CleanNetworkPlugin) for Codex
  or Claude Code, then use it in your consuming project.
  [Installation and first request](README_AI.md#install-the-plugin-recommended).
  Copilot users can [install the standalone skill](README_AI.md#install-the-standalone-skill-alternative).
- **Integrating by hand:** read the [integration guide](skills/ioscleannetwork/references/integration.md)
  and the [complete User example](skills/ioscleannetwork/assets/UserExample/).
- **Changing this SDK:** read [AGENTS.md](AGENTS.md).

The integration guide is the canonical technical reference for both workflows.
It ships inside the skill so its instructions and example remain available when
the skill is installed outside this repository.

## Installation

Add the package to your application's Swift package dependencies:

```swift
.package(url: "https://github.com/alegelos/iOSCleanNetwork", from: "1.0.4")
```

Add the runtime product to the target that implements your providers:

```swift
.product(name: "iOSCleanNetwork", package: "iOSCleanNetwork")
```

Add the test support product to your test target:

```swift
.product(name: "iOSCleanNetworkTesting", package: "iOSCleanNetwork")
```

In Xcode, use **File > Add Package Dependencies**, then select the appropriate
product for each target. Keep your existing dependency if the SDK is already
integrated. These examples use the API available in **1.0.4**; check the version
resolved by your app before adapting them.

## How an integration fits together

| Part | Responsibility | Example |
| --- | --- | --- |
| Domain model | Values used by the feature | `User`, `NewUser` |
| Domain protocol | Operations with domain inputs and outputs | `UserProviderProtocol` |
| Setup | URL, method, headers, query and encoded body | `UserAPISetup` |
| Request DTO | The API's request payload shape | `CreateUserDTO` |
| Response | The API's response payload shape and `.domain` mapping | `UserResponse` |
| Provider | Convert input, execute with an injected session, decode and map | `UserAPIProvider` |
| Test session | Load a response fixture instead of making a network call | `MockedURLSession` |

The SDK supplies the protocols, `URLSession` integration, HTTP validation,
optional unauthorized retry helper and test utilities. You implement the
feature-specific types above in your app. There is no automatic code generator
inside the Swift runtime.

The [User example provider](skills/ioscleannetwork/assets/UserExample/Sources/UserExample/Data/APIs/UserAPI/UserAPIProvider.swift)
demonstrates two operations on the same API:

```swift
// The feature works with Domain values.
let user = try await provider.getUser(id: 1)
let createdUser = try await provider.createUser(NewUser(name: "Sam"))
```

Its `UserDomain` target has no dependency on the SDK or the `UserData` target.
Inside Data, the provider encodes `CreateUserDTO` with `try`, sends a
`UserAPISetup` through `session.data(for:)`, decodes `UserResponse`, then returns
`response.domain`. The GET operation needs no request body or request DTO.

Use your app's established folder structure. For a new integration, keep
Domain models/protocols in Domain and Setup/Provider/DTO/Response types in Data.
The example's small, separate targets make that boundary verifiable; separate
targets are not required for every application.

## JSON fixtures and tests

The example's test-only extension maps each Setup case to a fixture filename
and sets `jsonBundle` to `.module`. Its test target declares the JSON directory
as SwiftPM resources. Both parts are necessary: the default bundle in
`URLSessionSetupProtocol` is `.main`.

Tests exercise the production provider with `MockedURLSession` and assert the
mapped Domain result. Separate tests inspect `setup.request` for URL, HTTP
method, headers and body. Loading a fixture does not validate request building
or simulate HTTP status codes.

The example also includes a handwritten provider spy. It records calls, can
inject an error, and otherwise forwards to the wrapped provider. The SDK
provides `ProviderSpyProtocol`, not your feature-specific spy classes.

See the [testing guidance](skills/ioscleannetwork/references/integration.md)
for Xcode bundles, failure cases, spies and testing presentation separately.

## Run the example

From this SDK checkout, on macOS 14+ with a Swift 6.2+ toolchain:

```sh
IOS_CLEAN_NETWORK_PATH="$PWD" swift test \
  --package-path skills/ioscleannetwork/assets/UserExample \
  --triple "$(uname -m)-apple-macosx14.0"
```

The explicit host target supplies the macOS availability needed by the SDK
and the testing toolchain. This is a host test of the shared
code, not an iOS simulator test or a new platform support guarantee.

For an iOS simulator, open the example's `Package.swift` in Xcode, select the
`UserExample` scheme and an available iOS simulator, then run the tests. Without
`IOS_CLEAN_NETWORK_PATH`, the example resolves the public package from 1.0.4.
Set that variable when validating changes in a local SDK checkout.

If a full Xcode installation is not your selected toolchain, prefix terminal
commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (adjust
the path for your installation).

## Authentication and limits

Authentication is supplied by your application. For token-based APIs,
`dataWithUnauthorizedRefreshRetry(apiAccessProvider:buildEndpoint:)` can obtain
a token, rebuild the Setup after a forced refresh and retry once after
`ApiErrors.unauthorized`. It does not implement token storage or an OAuth flow.

The current `HttpMethod` cases are GET, POST, PUT and PATCH. Inspect the installed
SDK before requesting other verbs. Decoder configuration, empty responses and
API-specific error bodies remain the consumer's responsibility. The
[integration guide](skills/ioscleannetwork/references/integration.md) describes
these boundaries and the exact contracts.

## AI-assisted integration

Installing the Swift package does **not** install instructions into an agent.
For Codex and Claude Code, install the
[CleanNetwork plugin](README_AI.md#install-the-plugin-recommended) to make the
integration guides, examples and testing workflow available to your agent.
One installation includes both the iOS and Android skills. Start a new session
in your consumer project and explicitly select the iOS skill for your first
request. The plugin is optional and the SDK dependency is installed separately.

For Copilot or a project-local setup, use the
[standalone skill](README_AI.md#install-the-standalone-skill-alternative).
The skill uses the open
[Agent Skills format](https://agentskills.io/specification); discovery and
invocation depend on the agent client. An instruction file improves context;
compilation, tests and review establish whether generated code is correct.
