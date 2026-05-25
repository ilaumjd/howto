import Foundation
import CryptoKit

/// Fetches HTML pages from the network with a configurable user-agent, timeout,
/// and an on-disk cache keyed by SHA256 hash of the URL.
struct WebFetchService {
    /// Browser-like user-agent string to avoid bot detection.
    let userAgent =
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36"

    private let cacheDirectory: URL
    private let cacheTTL: TimeInterval = 3600  // 1 hour
    private let requestTimeout: TimeInterval = 5

    /// Creates the service and ensures the on-disk cache directory exists.
    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.cacheDirectory = home.appendingPathComponent(".cache/howto")
        try? FileManager.default.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }

    /// Fetches the HTML content of the given URL. Returns a cached copy if
    /// available and fresh; otherwise performs a live HTTP request and caches it.
    func fetchHtmlPage(urlString: String) async throws -> String {
        let sanitizedURL = try sanitizeURL(urlString)

        // Check disk cache first
        if let cached = try? loadFromCache(url: sanitizedURL) {
            return cached
        }

        // Fetch from network
        guard let url = URL(string: sanitizedURL) else {
            throw WebFetchError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = requestTimeout

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200 ... 299).contains(httpResponse.statusCode)
            else {
                throw WebFetchError.noData
            }
            guard let html = String(data: data, encoding: .utf8) else {
                throw WebFetchError.noData
            }

            // Save to cache
            try? saveToCache(url: sanitizedURL, html: html)

            return html
        } catch let error as WebFetchError {
            throw error
        } catch {
            throw WebFetchError.networkError(error)
        }
    }

    // MARK: - Disk Cache

    private struct CacheEntry: Codable {
        let url: String
        let timestamp: Date
        let html: String
    }

    /// Returns a deterministic cache file path by SHA256-hashing the URL string.
    private func cacheFileURL(for urlString: String) -> URL {
        let hash = SHA256.hash(data: Data(urlString.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
        return cacheDirectory.appendingPathComponent(hash)
    }

    /// Reads a cache entry for the given URL. Returns `nil` if the entry is
    /// missing, expired (older than `cacheTTL`), or the stored URL doesn't match.
    private func loadFromCache(url: String) throws -> String? {
        let fileURL = cacheFileURL(for: url)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        let entry = try JSONDecoder().decode(CacheEntry.self, from: data)

        // Safety check — ensure the cached entry matches the requested URL
        guard entry.url == url else { return nil }

        // TTL check — purge expired entries
        guard Date().timeIntervalSince(entry.timestamp) < cacheTTL else {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }

        return entry.html
    }

    /// Writes a cache entry to disk.
    private func saveToCache(url: String, html: String) {
        let entry = CacheEntry(url: url, timestamp: Date(), html: html)
        guard let data = try? JSONEncoder().encode(entry) else { return }
        let fileURL = cacheFileURL(for: url)
        try? data.write(to: fileURL)
    }

    // MARK: - URL Sanitization

    /// Validates and sanitizes a URL string for safe HTTP requests.
    ///
    /// - Ensures the URL has an http:// or https:// scheme
    /// - Rejects relative paths (URLs without a scheme)
    /// - Rejects dangerous schemes like javascript:, mailto:, file:, ftp:, data:
    /// - Properly encodes query values using `urlQueryAllowed`
    private func sanitizeURL(_ urlString: String) throws -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw WebFetchError.invalidURL
        }

        // Parse and validate URL structure
        guard let url = URL(string: trimmed) else {
            throw WebFetchError.invalidURL
        }

        // Reject relative paths (no scheme present)
        guard let scheme = url.scheme?.lowercased() else {
            throw WebFetchError.invalidURL
        }

        // Only allow http and https — blocks javascript:, mailto:,
        // file:, ftp:, data:, and other non-HTTP schemes
        guard scheme == "https" || scheme == "http" else {
            throw WebFetchError.invalidURL
        }

        // Reconstruct the URL with proper encoding via URLComponents
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw WebFetchError.invalidURL
        }

        // Re-encode query items using urlQueryAllowed for proper encoding
        if let queryItems = components.queryItems {
            components.percentEncodedQueryItems = queryItems.map { item in
                URLQueryItem(
                    name: item.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                        ?? item.name,
                    value: item.value?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                        ?? item.value
                )
            }
        }

        guard let result = components.url?.absoluteString else {
            throw WebFetchError.invalidURL
        }

        return result
    }
}
