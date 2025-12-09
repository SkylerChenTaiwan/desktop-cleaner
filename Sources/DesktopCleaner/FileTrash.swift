import Foundation

/// 垃圾桶操作器 - 負責將檔案移到垃圾桶
class FileTrash {

    /// 將檔案移到垃圾桶
    /// - Parameter url: 檔案路徑
    /// - Returns: 是否成功移到垃圾桶
    func trash(at url: URL) -> Bool {
        do {
            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
            return true
        } catch {
            print("Error trashing \(url.lastPathComponent): \(error)")
            return false
        }
    }
}
