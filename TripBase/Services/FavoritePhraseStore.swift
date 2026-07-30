import Foundation

@MainActor
enum FavoritePhraseStore {
    private static let key = "favoritePhraseIDs"

    static var favoriteIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    static func isFavorite(_ phraseID: String) -> Bool {
        favoriteIDs.contains(phraseID)
    }

    static func toggle(_ phraseID: String) {
        var ids = favoriteIDs
        if ids.contains(phraseID) {
            ids.remove(phraseID)
        } else {
            ids.insert(phraseID)
        }
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}
