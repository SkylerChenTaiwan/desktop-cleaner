import Foundation

/// 簡易測試框架
public struct TestFramework {
    public static var passed = 0
    public static var failed = 0
    public static var errors: [(String, String)] = []

    public static func assert(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
        if condition {
            passed += 1
            print("  ✅ \(message)")
        } else {
            failed += 1
            let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(line)"
            errors.append((location, message))
            print("  ❌ \(message)")
        }
    }

    public static func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String, file: String = #file, line: Int = #line) {
        if actual == expected {
            passed += 1
            print("  ✅ \(message)")
        } else {
            failed += 1
            let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(line)"
            errors.append((location, "\(message) - Expected: \(expected), Got: \(actual)"))
            print("  ❌ \(message)")
            print("     Expected: \(expected)")
            print("     Got:      \(actual)")
        }
    }

    public static func runSuite(_ name: String, _ tests: () throws -> Void) {
        print("\n📦 \(name)")
        print(String(repeating: "-", count: 50))
        do {
            try tests()
        } catch {
            failed += 1
            errors.append(("Suite", "Error in \(name): \(error)"))
            print("  ❌ Suite error: \(error)")
        }
    }

    public static func runTest(_ name: String, _ test: () throws -> Void) {
        print("\n🧪 \(name)")
        do {
            try test()
        } catch {
            failed += 1
            errors.append(("Test", "Error in \(name): \(error)"))
            print("  ❌ Test error: \(error)")
        }
    }

    public static func printSummary() {
        print("\n" + String(repeating: "=", count: 50))
        print("📊 測試結果摘要")
        print(String(repeating: "=", count: 50))
        print("✅ 通過: \(passed)")
        print("❌ 失敗: \(failed)")
        print("📝 總計: \(passed + failed)")

        if !errors.isEmpty {
            print("\n❌ 失敗詳情:")
            for (location, message) in errors {
                print("  [\(location)] \(message)")
            }
        }

        print(String(repeating: "=", count: 50))
    }

    public static func exitWithStatus() -> Never {
        if failed > 0 {
            exit(1)
        } else {
            exit(0)
        }
    }

    public static func reset() {
        passed = 0
        failed = 0
        errors = []
    }
}

/// 測試用臨時目錄
public struct TestDirectory {
    public let url: URL

    public init() throws {
        url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    public func cleanup() {
        try? FileManager.default.removeItem(at: url)
    }
}
