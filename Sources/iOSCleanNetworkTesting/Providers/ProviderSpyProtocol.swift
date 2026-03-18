import Testing
import Foundation

/// A lightweight **test-double mixin** for spies that:
/// 1) **Counts** how many times each method is called, and
/// 2) **Triggers failures in a programmable order**, by throwing pre-queued errors for a given method.
///
/// ### How to use
/// - Define an enum `MethodKey` listing the methods you want to observe.
/// - Add stored properties:
///     - `var methosCallsCounts: [MethodKey: Int] = [:]`
///     - `var failingMethos: [(method: MethodKey, error: Error)] = []`
/// - At the start of each spied method:
///     1) call `increment(_:)`
///     2) call `try validateFailingMethods(method:)`
///
/// ### Failure policy
/// - Failures are queued globally as `(method, error)` pairs in **insertion order**.
/// - `validateFailingMethods(method:)` looks for the **first queued item whose `method` matches**
///   the passed `method`, **removes it**, and **throws** the associated `error`.
///   (It does **not** require the match to be at the head of the list.)
///
/// ### Requirements
/// - `Hashable` is needed to use `MethodKey` as a dictionary key.
/// - `CaseIterable` is used to assert that methods **not listed** in expectations were called **0** times.
public protocol ProviderSpyProtocol: AnyObject {

    associatedtype MethodKey: Hashable & CaseIterable

    /// Per-method counters: how many times each method was called.
    var invocationsCount: [MethodKey: Int] { get set }

    /// Globally ordered queue of planned failures:
    /// append `(method, error)` to make the next call for that `method` throw `error`.
    var failingMethos: [(method: MethodKey, error: Error)] { get set }

    /// Increase the call count for `method` by 1.
    /// - Parameter method: Method to increment in `methosCallsCounts`.
    func increment(_ method: MethodKey)

    /// Reset **all** call counters back to 0.
    func resetInvocationsCount()

    /// Assert that each `(method, expectedCount)` matches the actual count and that
    /// any **other** method (not listed) has a count of **0**.
    /// - Parameter expectations: Expected call counts per method.
    func assertExpectedInvocations(
        _ expectations: [(MethodKey, Int)],
        sourceLocation: SourceLocation
    )

    /// Queue explicit `(method, error)` failures in order (FIFO **per insertion**).
    /// Each tuple represents **one** failing call for that method.
    func failingMethods(_ items: [(MethodKey, Error)])

    /// Consume and throw the next queued failure for `method` (if any).
    /// If no failure is queued for `method`, the call proceeds normally.
    func validateFailingMethods(method: MethodKey) throws
}

// MARK: - Default behaviour

public extension ProviderSpyProtocol {

    /// Increase the call count for `method` by `1`.
    func increment(_ method: MethodKey) {
        invocationsCount[method, default: .zero] += 1
    }

    /// Reset **all** call counters to `0`.
    func resetInvocationsCount() {
        invocationsCount.removeAll()
    }

    /// Queue explicit `(method, error)` failures in order (FIFO).
    /// Each tuple represents one failing invocation for that method.
    func failingMethods(_ items: [(MethodKey, Error)]) {
        for (method, error) in items {
            failingMethos.append((method: method, error: error))
        }
    }

    /// If a queued failure exists for `method`, remove **the first matching entry** and throw its error.
    /// If no matching entry exists, do nothing (call proceeds normally).
    func validateFailingMethods(method: MethodKey) throws {
        if let index = failingMethos.firstIndex(where: { $0.method == method }) {
            let (_, error) = failingMethos.remove(at: index)
            throw error
        }
    }

    /// Assert that:
    /// 1) Every provided `(method, expectedCount)` equals the actual count, and
    /// 2) Every **other** method has a count of **0**.
    func assertExpectedInvocations(
        _ expectations: [(MethodKey, Int)],
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        var seen = Set<MethodKey>()

        // Assert provided expectations
        for (method, expected) in expectations {
            seen.insert(method)
            let actual = invocationsCount[method, default: 0]
            if actual != expected {
                Issue.record("\(method) - Actual: \(actual), Expected = \(expected)", sourceLocation: sourceLocation)
            }
        }

        // Assert the rest are zero
        for method in MethodKey.allCases where seen.contains(method) == false {
            let actual = invocationsCount[method, default: 0]
            if actual != .zero {
                Issue.record("\(method) - Actual: \(actual), Expected = 0", sourceLocation: sourceLocation)
            }
        }
    }

}
