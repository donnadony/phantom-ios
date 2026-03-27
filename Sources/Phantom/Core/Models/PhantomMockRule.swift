import Foundation

public struct PhantomMockResponse: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var httpMethod: String
    public var statusCode: Int
    public var responseBody: String

    public init(id: UUID = UUID(), name: String, httpMethod: String = "ANY", statusCode: Int, responseBody: String) {
        self.id = id
        self.name = name
        self.httpMethod = httpMethod
        self.statusCode = statusCode
        self.responseBody = responseBody
    }

    enum CodingKeys: String, CodingKey {
        case id, name, httpMethod, statusCode, responseBody
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        httpMethod = try container.decodeIfPresent(String.self, forKey: .httpMethod) ?? "ANY"
        statusCode = try container.decode(Int.self, forKey: .statusCode)
        responseBody = try container.decode(String.self, forKey: .responseBody)
    }
}

public struct PhantomMockRule: Codable, Identifiable {

    public let id: UUID
    public var isEnabled: Bool
    public var urlPattern: String
    public var httpMethod: String
    public var responses: [PhantomMockResponse]
    public var activeResponseId: UUID?
    public var ruleDescription: String
    public var createdAt: Date

    public var activeResponse: PhantomMockResponse? {
        guard let activeId = activeResponseId else { return responses.first }
        return responses.first { $0.id == activeId } ?? responses.first
    }

    public init(
        id: UUID = UUID(),
        isEnabled: Bool = true,
        urlPattern: String,
        httpMethod: String = "ANY",
        responses: [PhantomMockResponse],
        activeResponseId: UUID? = nil,
        ruleDescription: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.urlPattern = urlPattern
        self.httpMethod = httpMethod
        self.responses = responses
        self.activeResponseId = activeResponseId
        self.ruleDescription = ruleDescription
        self.createdAt = createdAt
    }
}

public enum PhantomHTTPStatusCode {

    public struct Entry: Identifiable {
        public let code: Int
        public let label: String
        public var id: Int { code }
    }

    public struct Group: Identifiable {
        public let title: String
        public let entries: [Entry]
        public var id: String { title }
    }

    public static let common: [Entry] = [
        Entry(code: 200, label: "OK"),
        Entry(code: 201, label: "Created"),
        Entry(code: 204, label: "No Content"),
        Entry(code: 400, label: "Bad Request"),
        Entry(code: 401, label: "Unauthorized"),
        Entry(code: 403, label: "Forbidden"),
        Entry(code: 404, label: "Not Found"),
        Entry(code: 500, label: "Internal Server Error")
    ]

    public static let grouped: [Group] = [
        Group(title: "1xx - Informational", entries: [
            Entry(code: 100, label: "Continue"),
            Entry(code: 101, label: "Switching Protocols"),
            Entry(code: 102, label: "Processing"),
            Entry(code: 103, label: "Early Hints")
        ]),
        Group(title: "2xx - Successful", entries: [
            Entry(code: 200, label: "OK"),
            Entry(code: 201, label: "Created"),
            Entry(code: 202, label: "Accepted"),
            Entry(code: 204, label: "No Content"),
            Entry(code: 206, label: "Partial Content"),
            Entry(code: 207, label: "Multi-Status")
        ]),
        Group(title: "3xx - Redirection", entries: [
            Entry(code: 301, label: "Moved Permanently"),
            Entry(code: 302, label: "Found"),
            Entry(code: 304, label: "Not Modified"),
            Entry(code: 307, label: "Temporary Redirect"),
            Entry(code: 308, label: "Permanent Redirect")
        ]),
        Group(title: "4xx - Client Error", entries: [
            Entry(code: 400, label: "Bad Request"),
            Entry(code: 401, label: "Unauthorized"),
            Entry(code: 403, label: "Forbidden"),
            Entry(code: 404, label: "Not Found"),
            Entry(code: 405, label: "Method Not Allowed"),
            Entry(code: 408, label: "Request Timeout"),
            Entry(code: 409, label: "Conflict"),
            Entry(code: 422, label: "Unprocessable Entity"),
            Entry(code: 429, label: "Too Many Requests")
        ]),
        Group(title: "5xx - Server Error", entries: [
            Entry(code: 500, label: "Internal Server Error"),
            Entry(code: 501, label: "Not Implemented"),
            Entry(code: 502, label: "Bad Gateway"),
            Entry(code: 503, label: "Service Unavailable"),
            Entry(code: 504, label: "Gateway Timeout")
        ])
    ]
}
