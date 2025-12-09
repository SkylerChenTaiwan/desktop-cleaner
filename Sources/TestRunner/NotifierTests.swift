import Foundation
import DesktopCleanerLib

/// Notifier 測試套件
struct NotifierTests {
    static func runAll() {
        TestFramework.runSuite("NotifierTests") {
            testMessageWithCleanedFiles()
            testMessageWithNoFiles()
            testMessageWithErrors()
        }
    }

    /// 測試：有清理檔案時的訊息格式
    static func testMessageWithCleanedFiles() {
        TestFramework.runTest("通知訊息格式正確（有清理）") {
            let notifier = Notifier()

            // 清理 5 個檔案，無錯誤
            let message = notifier.buildMessage(trashedCount: 5, errorCount: 0)
            TestFramework.assertEqual(message, "已清理 5 個檔案", "清理 5 個檔案的訊息")

            // 清理 1 個檔案
            let message1 = notifier.buildMessage(trashedCount: 1, errorCount: 0)
            TestFramework.assertEqual(message1, "已清理 1 個檔案", "清理 1 個檔案的訊息")
        }
    }

    /// 測試：沒有檔案需要清理時的訊息
    static func testMessageWithNoFiles() {
        TestFramework.runTest("通知訊息格式正確（無清理）") {
            let notifier = Notifier()

            let message = notifier.buildMessage(trashedCount: 0, errorCount: 0)
            TestFramework.assertEqual(message, "沒有需要清理的檔案", "無檔案需要清理的訊息")
        }
    }

    /// 測試：有錯誤時的訊息格式
    static func testMessageWithErrors() {
        TestFramework.runTest("通知訊息格式正確（有錯誤）") {
            let notifier = Notifier()

            // 清理 3 個檔案，1 個錯誤
            let message = notifier.buildMessage(trashedCount: 3, errorCount: 1)
            TestFramework.assertEqual(message, "已清理 3 個檔案，1 個錯誤", "有錯誤的訊息")

            // 清理 5 個檔案，2 個錯誤
            let message2 = notifier.buildMessage(trashedCount: 5, errorCount: 2)
            TestFramework.assertEqual(message2, "已清理 5 個檔案，2 個錯誤", "多個錯誤的訊息")

            // 0 個清理，有錯誤
            let message3 = notifier.buildMessage(trashedCount: 0, errorCount: 3)
            TestFramework.assertEqual(message3, "沒有需要清理的檔案，3 個錯誤", "只有錯誤的訊息")
        }
    }
}
