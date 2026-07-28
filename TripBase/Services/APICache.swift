import Foundation

struct CachedValue<T: Codable>: Codable {
    let payload: T
    let fetchedAt: Date
}

struct FetchResult<T> {
    let value: T?
    let isStale: Bool
    let fetchedAt: Date?
}

enum APICache {
    private static var cacheDirectory: URL {
        let directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("APICache", isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    private static func fileURL(for key: String) -> URL {
        let safeKey = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return cacheDirectory.appendingPathComponent("\(safeKey).json")
    }

    static func save<T: Codable>(_ value: T, key: String) {
        let cached = CachedValue(payload: value, fetchedAt: .now)
        guard let data = try? JSONEncoder().encode(cached) else { return }
        try? data.write(to: fileURL(for: key), options: .atomic)
    }

    static func load<T: Codable>(_ type: T.Type, key: String) -> CachedValue<T>? {
        guard let data = try? Data(contentsOf: fileURL(for: key)) else { return nil }
        return try? JSONDecoder().decode(CachedValue<T>.self, from: data)
    }

    /// Tries a live fetch first; on failure, falls back to the last cached
    /// value for `key` if one exists, marking the result as stale.
    static func fetch<T: Codable>(key: String, live: () async throws -> T) async -> FetchResult<T> {
        do {
            let value = try await live()
            save(value, key: key)
            return FetchResult(value: value, isStale: false, fetchedAt: .now)
        } catch {
            if let cached = load(T.self, key: key) {
                return FetchResult(value: cached.payload, isStale: true, fetchedAt: cached.fetchedAt)
            }
            return FetchResult(value: nil, isStale: false, fetchedAt: nil)
        }
    }
}
