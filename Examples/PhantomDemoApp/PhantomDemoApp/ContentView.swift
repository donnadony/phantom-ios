import SwiftUI
import Phantom

struct ContentView: View {

    @State private var posts: [Post] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                instructionBanner
                postList
            }
            .navigationTitle("Phantom Demo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fetch Posts") { fetchPosts() }
                }
            }
        }
        .onAppear { fetchPosts() }
    }

    private var instructionBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "iphone.radiowaves.left.and.right")
                .foregroundColor(.blue)
            Text("Shake the device to open Phantom")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var postList: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.secondary)
                    Button("Retry") { fetchPosts() }
                }
                .frame(maxHeight: .infinity)
            } else {
                List(posts) { post in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.title)
                            .font(.headline)
                        Text(post.body)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func fetchPosts() {
        let baseURL = Phantom.config("api_base_url") ?? "https://jsonplaceholder.typicode.com"
        guard let url = URL(string: "\(baseURL)/posts") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        Phantom.logRequest(request)
        Phantom.log(.info, "Fetching posts from \(baseURL)", tag: "Network")

        if let (mockData, mockResponse) = Phantom.mockResponse(for: request) {
            Phantom.log(.info, "Using mock response (\(mockResponse.statusCode))", tag: "Mock")
            handleResponse(data: mockData, statusCode: mockResponse.statusCode)
            return
        }

        isLoading = true
        errorMessage = nil

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false

                if let error = error {
                    Phantom.log(.error, error.localizedDescription, tag: "Network")
                    Phantom.logResponse(for: request, response: response, errorMessage: error.localizedDescription)
                    errorMessage = error.localizedDescription
                    return
                }

                let statusCode = (response as? HTTPURLResponse)?.statusCode
                Phantom.logResponse(for: request, response: response, body: data)
                handleResponse(data: data, statusCode: statusCode)
            }
        }.resume()
    }

    private func handleResponse(data: Data?, statusCode: Int?) {
        guard let data = data else {
            errorMessage = "No data received"
            return
        }

        guard let code = statusCode, (200...299).contains(code) else {
            Phantom.log(.error, "Request failed with status \(statusCode ?? -1)", tag: "Network")
            errorMessage = "Server error (\(statusCode ?? -1))"
            return
        }

        do {
            let decoded = try JSONDecoder().decode([Post].self, from: data)
            posts = decoded
            Phantom.log(.info, "Loaded \(decoded.count) posts", tag: "Network")
        } catch {
            Phantom.log(.error, "Decode error: \(error.localizedDescription)", tag: "Network")
            errorMessage = "Failed to parse response"
        }
    }
}

struct Post: Identifiable, Decodable {
    let id: Int
    let title: String
    let body: String
}
