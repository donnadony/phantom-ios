import SwiftUI

struct PhantomNetworkView: View {

    @Environment(\.phantomTheme) private var theme
    @StateObject private var viewModel = PhantomNetworkViewModel()

    var body: some View {
        VStack(spacing: 0) {
            searchView
            filterView
            listView
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Network (\(viewModel.totalCount))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.clearAll() }) {
                    Text("Clear")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.error)
                }
            }
        }
    }

    private var searchView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.onBackgroundVariant)
            TextField("Filter by endpoint, body or headers", text: $viewModel.searchText)
                .font(.system(size: 14))
                .foregroundStyle(theme.onBackground)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var filterView: some View {
        HStack(spacing: 8) {
            ForEach(PhantomNetworkViewModel.FilterType.allCases) { filter in
                Button(action: { viewModel.selectedFilter = filter }) {
                    Text(filter.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(viewModel.selectedFilter == filter ? theme.onPrimary : theme.onBackground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.selectedFilter == filter ? theme.primary : theme.surface)
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.filteredLogs) { item in
                    NavigationLink(destination: detailDestination(for: item)) {
                        logRow(item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private func detailDestination(for item: PhantomNetworkItem) -> some View {
        PhantomNetworkDetailView(item: item)
            .environment(\.phantomTheme, theme)
    }

    private func logRow(_ item: PhantomNetworkItem) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(viewModel.statusColor(item, theme: theme))
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.methodType)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(viewModel.methodColor(for: item.methodType, theme: theme))
                    statusBadge(for: item)
                    if viewModel.isMockLog(item) {
                        Text("MOCK")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(theme.onPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 8).fill(theme.warning))
                    }
                }
                Text(viewModel.pathText(for: item))
                    .font(.system(size: 12))
                    .foregroundStyle(theme.onBackgroundVariant)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(viewModel.timeText(item.createdAt))
                        .font(.system(size: 12))
                        .foregroundStyle(theme.onBackgroundVariant)
                    if let duration = item.durationMs {
                        Text("\(duration)ms")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(duration > 1000 ? theme.error : theme.onBackgroundVariant)
                    }
                    if item.responseSizeBytes > 0 {
                        Text(viewModel.formattedBytes(item.responseSizeBytes))
                            .font(.system(size: 12))
                            .foregroundStyle(theme.onBackgroundVariant)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(theme.onBackgroundVariant)
                .padding(.top, 6)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.outlineVariant, lineWidth: 1))
    }

    @ViewBuilder
    private func statusBadge(for item: PhantomNetworkItem) -> some View {
        if let status = item.statusCode {
            Text("\(status)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(viewModel.statusTextColor(for: status, theme: theme))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 8).fill(viewModel.statusBackgroundColor(for: status, theme: theme)))
        } else {
            Text(item.completedAt == nil ? "PENDING" : "DONE")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(theme.onBackground)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 8).fill(theme.surfaceVariant))
        }
    }
}
