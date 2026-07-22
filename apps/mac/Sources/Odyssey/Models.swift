import Foundation

struct CosmosElement: Codable, Identifiable {
    let id: Int
    let url: String
    let width: Int?
    let height: Int?
    let type: String
    let sourceUrl: String?

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
