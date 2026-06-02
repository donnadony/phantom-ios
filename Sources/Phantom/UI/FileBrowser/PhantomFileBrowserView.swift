import SwiftUI

struct PhantomFileBrowserView: View {

    @Environment(\.phantomTheme) private var theme
    @StateObject private var viewModel: PhantomFileBrowserViewModel
    @State private var itemToDelete: PhantomFileBrowserViewModel.FileItem?

    init(directory: URL? = nil, title: String? = nil) {
        _viewModel = StateObject(wrappedValue: PhantomFileBrowserViewModel(directory: directory, title: title))
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            if viewModel.items.isEmpty {
                emptyState
            } else {
                fileList
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showPreview) {
            previewSheet
        }
        .actionSheet(isPresented: Binding(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )) {
            ActionSheet(
                title: Text("Delete \(itemToDelete?.name ?? "")?"),
                message: Text("This action cannot be undone."),
                buttons: [
                    .destructive(Text("Delete")) {
                        if let item = itemToDelete {
                            viewModel.deleteItem(item)
                        }
                    },
                    .cancel()
                ]
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "folder")
                .font(.system(size: 40))
                .foregroundColor(theme.onBackgroundVariant)
            Text("Empty directory")
                .font(.system(size: 14))
                .foregroundColor(theme.onBackgroundVariant)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fileList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.items) { item in
                    if item.isDirectory {
                        NavigationLink(destination: subdirectoryView(for: item)) {
                            fileRow(item)
                        }
                        .buttonStyle(.plain)
                    } else if viewModel.canPreview(item) {
                        Button(action: { viewModel.previewFile(item) }) {
                            fileRow(item)
                        }
                        .buttonStyle(.plain)
                    } else {
                        fileRow(item)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private func subdirectoryView(for item: PhantomFileBrowserViewModel.FileItem) -> some View {
        PhantomFileBrowserView(directory: item.url, title: item.name)
            .environment(\.phantomTheme, theme)
    }

    private func fileRow(_ item: PhantomFileBrowserViewModel.FileItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: viewModel.iconName(for: item))
                .font(.system(size: 18))
                .foregroundColor(item.isDirectory ? theme.primary : theme.onBackgroundVariant)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 14, weight: item.isDirectory ? .semibold : .regular))
                    .foregroundColor(theme.onBackground)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    if !item.isDirectory {
                        Text(viewModel.formattedSize(item.size))
                            .font(.system(size: 12))
                            .foregroundColor(theme.onBackgroundVariant)
                    }
                    if let date = item.modifiedDate {
                        Text(viewModel.formattedDate(date))
                            .font(.system(size: 12))
                            .foregroundColor(theme.onBackgroundVariant)
                    }
                }
            }
            Spacer()
            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(theme.onBackgroundVariant)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.outlineVariant, lineWidth: 1))
        .contextMenu {
            if !item.isDirectory && viewModel.canPreview(item) {
                Button(action: { viewModel.previewFile(item) }) {
                    Label("Preview", systemImage: "eye")
                }
            }
            Button(action: { itemToDelete = item }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var previewSheet: some View {
        NavigationView {
            ScrollView {
                Text(viewModel.previewContent ?? "")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(theme.onBackground)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(viewModel.previewTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { viewModel.showPreview = false }
                        .foregroundColor(theme.primary)
                }
            }
        }
    }
}
