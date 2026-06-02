import SwiftUI

struct PhantomDeepLinkView: View {

    @Environment(\.phantomTheme) private var theme
    @StateObject private var viewModel = PhantomDeepLinkViewModel()

    var body: some View {
        VStack(spacing: 0) {
            inputSection
            if let error = viewModel.errorMessage {
                errorBanner(error)
            }
            if viewModel.history.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Deep Link Tester")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.history.isEmpty {
                    Button(action: { viewModel.clearHistory() }) {
                        Text("Clear")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.error)
                    }
                }
            }
        }
    }

    private var inputSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .foregroundColor(theme.onBackgroundVariant)
                TextField("myapp://path or https://...", text: $viewModel.urlText)
                    .font(.system(size: 14))
                    .foregroundColor(theme.onBackground)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                if !viewModel.urlText.isEmpty {
                    Button(action: { viewModel.urlText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(theme.onBackgroundVariant)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface))

            Button(action: { viewModel.openLink() }) {
                HStack {
                    Image(systemName: "arrow.up.right.square")
                    Text("Open Link")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(theme.onPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.primary))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
            Text(message)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(theme.error)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "link.circle")
                .font(.system(size: 40))
                .foregroundColor(theme.onBackgroundVariant)
            Text("No history yet")
                .font(.system(size: 14))
                .foregroundColor(theme.onBackgroundVariant)
            Text("Enter a URL scheme or universal link above")
                .font(.system(size: 12))
                .foregroundColor(theme.onBackgroundVariant)
            Spacer()
        }
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.onBackgroundVariant)
                .padding(.horizontal, 16)
                .padding(.top, 4)
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.history) { item in
                        historyRow(item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 6)
            }
        }
    }

    private func historyRow(_ item: PhantomDeepLinkViewModel.HistoryItem) -> some View {
        Button(action: { viewModel.selectHistoryItem(item) }) {
            HStack(spacing: 10) {
                Image(systemName: item.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(item.success ? theme.success : theme.error)
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.url)
                        .font(.system(size: 13))
                        .foregroundColor(theme.onBackground)
                        .lineLimit(1)
                    Text(viewModel.timeText(item.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(theme.onBackgroundVariant)
                }
                Spacer()
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.outlineVariant, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
