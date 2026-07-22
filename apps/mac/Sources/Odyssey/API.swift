import Foundation

enum APIError: LocalizedError {
    case badResponse(String)

    var errorDescription: String? {
        switch self {
        case .badResponse(let message): return message
        }
    }
}

struct API {
    static let baseURL = URL(string: "https://odyssey-hq.vercel.app")!

    // On-disk cache so repeat launches reuse responses (honors server Cache-Control).
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 32 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024
        )
        config.requestCachePolicy = .useProtocolCachePolicy
        return URLSession(configuration: config)
    }()

    private static func url(_ path: String, query: [String: String]) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url!
    }

    // Synchronously read a previously cached response, if any. Lets the UI show
    // stale data instantly while a fresh request revalidates in the background.
    private static func cached<T: Decodable>(_ path: String, query: [String: String]) -> T? {
        let request = URLRequest(url: url(path, query: query))
        guard let data = session.configuration.urlCache?.cachedResponse(for: request)?.data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func get<T: Decodable>(_ path: String, query: [String: String]) async throws -> T {
        let (data, response) = try await session.data(from: url(path, query: query))

        guard let http = response as? HTTPURLResponse else {
            throw APIError.badResponse("No response")
        }

        if http.statusCode >= 400 {
            if let apiError = try? JSONDecoder().decode(ApiError.self, from: data) {
                throw APIError.badResponse(apiError.error)
            }
            throw APIError.badResponse("Request failed (\(http.statusCode))")
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    static func resolve(username: String) async throws -> ResolveResponse {
        try await get("api/cosmos/resolve", query: ["username": username])
    }

    static func cachedResolve(username: String) -> ResolveResponse? {
        cached("api/cosmos/resolve", query: ["username": username])
    }

    static func elements(userId: String, cursor: String) async throws -> ElementsResponse {
        try await get("api/cosmos/elements", query: ["userId": userId, "cursor": cursor])
    }

    static func clusters(userId: String) async throws -> ClustersResponse {
        try await get("api/cosmos/clusters", query: ["userId": userId])
    }

    static func clusterElements(clusterId: Int, cursor: String?) async throws -> ElementsResponse {
        var query = ["clusterId": String(clusterId)]
        if let cursor { query["cursor"] = cursor }
        return try await get("api/cosmos/cluster-elements", query: query)
    }
}
