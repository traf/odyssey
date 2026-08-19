import Foundation

struct CosmosElement: Codable, Identifiable {
    let id: Int
    let url: String
    let width: Int?
    let height: Int?
    let type: String
    let sourceUrl: String?
    // Palette from Cosmos, dominant swatch first. Optional: cached responses
    // predating the field decode without it, and search hits never carry one.
    let colors: [String]?

    var ratio: CGFloat {
        guard let w = width, let h = height, w > 0, h > 0 else { return 1 }
        return CGFloat(w) / CGFloat(h)
    }

    var source: URL? {
        guard let sourceUrl, let url = URL(string: sourceUrl) else { return nil }
        return url
    }

    var cosmosUrl: URL? {
        URL(string: "https://www.cosmos.so/e/\(id)")
    }

    // The CDN renders on demand, and nothing here ever needs the original: tiles
    // are a few hundred points wide while the sources average a couple of
    // megapixels, and it's decoded pixels — not bytes — that cost memory and
    // heat. Widths snap to 200px steps so zooming reuses a rendition already
    // cached instead of asking for a slightly different one each time.
    func image(width points: CGFloat) -> URL? {
        guard points > 0, var components = URLComponents(string: url) else { return nil }
        let pixels = min(Self.maxRendition, Int((points * 2 / 200).rounded(.up)) * 200)
        components.queryItems = [
            URLQueryItem(name: "format", value: "webp"),
            URLQueryItem(name: "w", value: String(pixels)),
        ]
        return components.url
    }

    private static let maxRendition = 2400
}

struct UserProfile: Codable {
    let id: String
    let username: String
    let displayName: String
    let avatarUrl: String?
}

struct ResolveResponse: Codable {
    let user: UserProfile
    let elements: [CosmosElement]
    let nextCursor: String?
    let totalCount: Int
}

struct ElementsResponse: Codable {
    let elements: [CosmosElement]
    let nextCursor: String?
}

struct CosmosCluster: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
    let numberOfElements: Int
    let coverImageUrl: String?
}

struct ClustersResponse: Codable {
    let clusters: [CosmosCluster]
}

struct ApiError: Codable {
    let error: String
}
