import Foundation

/// Disk-backed storage for document attachments (photos/PDFs), mirroring
/// APICache's applicationSupportDirectory pattern. Only the filename is
/// stored on the TripDocument model - the file itself lives on disk.
enum TripDocumentStorage {
    private static var directory: URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TripDocumentAttachments", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    @discardableResult
    static func store(data: Data, fileExtension: String) throws -> String {
        let filename = "\(UUID().uuidString).\(fileExtension)"
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return filename
    }

    static func url(for filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }

    static func delete(_ filename: String) {
        try? FileManager.default.removeItem(at: url(for: filename))
    }
}
