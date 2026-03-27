import SwiftUI

struct PhantomNetworkDetailView: View {

    @Environment(\.phantomTheme) private var theme
    @StateObject private var viewModel: PhantomNetworkDetailViewModel

    init(item: PhantomNetworkItem) {
        _viewModel = StateObject(wrappedValue: PhantomNetworkDetailViewModel(item: item))
    }

    var body: some View {
        VStack(spacing: 0) {
            urlHeader
            tabPicker
            tabContent
            bottomActions
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("\(viewModel.item.methodType) \(viewModel.statusText)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.mockRuleToCreate) { rule in
            PhantomMockEditView(existingRule: rule, onSave: { viewModel.handleMockCreated($0) })
                .environment(\.phantomTheme, theme)
        }
        .sheet(item: $viewModel.mockRuleToEdit) { rule in
            PhantomMockEditView(existingRule: rule, onSave: { viewModel.handleMockUpdated($0) })
                .environment(\.phantomTheme, theme)
        }
    }

    private var urlHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.item.url?.absoluteString ?? "No URL")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.onBackground)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                statusBadge
                if let duration = viewModel.item.durationMs {
                    Text("\(duration)ms")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(duration > 1000 ? theme.error : theme.onBackgroundVariant)
                }
                if viewModel.item.responseSizeBytes > 0 {
                    Text(viewModel.formattedBytes)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.onBackgroundVariant)
                }
                if viewModel.isMock {
                    Text("MOCK")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(theme.onPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 6).fill(theme.warning))
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface)
    }

    private var statusBadge: some View {
        Group {
            if let status = viewModel.item.statusCode {
                Text("\(status)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(viewModel.statusTextColor(theme: theme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 6).fill(viewModel.statusBackgroundColor(theme: theme)))
            }
        }
    }

    private var tabPicker: some View {
        Picker("", selection: $viewModel.selectedTab) {
            ForEach(PhantomNetworkDetailViewModel.DetailTab.allCases) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var tabContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            viewToggle
            ScrollView {
                if viewModel.showJsonTree {
                    jsonTreeContent
                } else {
                    plainTextContent
                }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface))
        .padding(.horizontal, 16)
        .frame(maxHeight: .infinity)
    }

    private var viewToggle: some View {
        HStack {
            HStack(spacing: 0) {
                Button(action: { viewModel.showJsonTree = true }) {
                    Text("Viewer")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(viewModel.showJsonTree ? theme.onBackground : theme.onBackgroundVariant)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(viewModel.showJsonTree ? theme.surfaceVariant : .clear)
                        )
                }
                Button(action: { viewModel.showJsonTree = false }) {
                    Text("Text")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(!viewModel.showJsonTree ? theme.onBackground : theme.onBackgroundVariant)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(!viewModel.showJsonTree ? theme.surfaceVariant : .clear)
                        )
                }
            }
            .background(RoundedRectangle(cornerRadius: 6).fill(theme.surface))
            Spacer()
            Button(action: { viewModel.copyCurrentTab() }) {
                HStack(spacing: 4) {
                    Image(systemName: viewModel.copiedMessage != nil ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11))
                    Text(viewModel.copiedMessage ?? "Copy")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(theme.info)
            }
        }
    }

    @ViewBuilder
    private var jsonTreeContent: some View {
        switch viewModel.selectedTab {
        case .request:
            PhantomJsonTreeView(jsonString: viewModel.item.requestBody)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .response:
            PhantomJsonTreeView(jsonString: viewModel.item.responseBody)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .headers:
            headersTreeContent
        }
    }

    private var headersTreeContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.item.requestHeaders.isEmpty && viewModel.item.requestHeaders != "No headers" {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Request Headers")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                    PhantomJsonTreeView(jsonString: viewModel.headersAsJson(viewModel.item.requestHeaders))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if !viewModel.item.responseHeaders.isEmpty && viewModel.item.responseHeaders != "No headers" {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Response Headers")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                    PhantomJsonTreeView(jsonString: viewModel.headersAsJson(viewModel.item.responseHeaders))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if viewModel.item.requestHeaders == "No headers" && viewModel.item.responseHeaders == "No headers" {
                Text("No headers")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(theme.onBackgroundVariant)
            }
        }
    }

    @ViewBuilder
    private var plainTextContent: some View {
        Text(viewModel.plainText)
            .font(.system(size: 12, weight: .regular, design: .monospaced))
            .foregroundStyle(theme.onBackground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
    }

    private var bottomActions: some View {
        HStack {
            Spacer()
            if viewModel.isMock {
                Button(action: { viewModel.editMock() }) {
                    Text("Edit Mock")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.onPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(theme.warning))
                }
                Button(action: { viewModel.copyCurl() }) {
                    Text("Copy cURL")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.onPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(theme.success))
                }
            } else {
                Button(action: { viewModel.createMock() }) {
                    Text("Mock this")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.onPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(theme.info))
                }
                Button(action: { viewModel.copyCurl() }) {
                    Text("Copy cURL")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.onPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(theme.success))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
