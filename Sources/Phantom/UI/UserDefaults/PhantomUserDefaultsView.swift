import SwiftUI

struct PhantomUserDefaultsView: View {

    @Environment(\.phantomTheme) private var theme
    @StateObject private var viewModel = PhantomUserDefaultsViewModel()
    @State private var showClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            filterBar
            if viewModel.filteredEntries.isEmpty {
                Spacer()
                Text("No entries found.")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.onBackgroundVariant)
                Spacer()
            } else {
                entryList
            }
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("UserDefaults (\(viewModel.filteredEntries.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button(action: { viewModel.showAddSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundStyle(theme.primary)
                    }
                    Button(action: { showClearConfirmation = true }) {
                        Text("Clear")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.error)
                    }
                }
            }
        }
        .confirmationDialog(
            "Clear \(viewModel.selectedGroup.rawValue) entries?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear \(viewModel.filteredEntries.count) keys", role: .destructive) {
                viewModel.clearFilteredKeys()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove \(viewModel.filteredEntries.count) UserDefaults keys. This cannot be undone.")
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            PhantomUserDefaultsEditView { key, value, type in
                viewModel.addEntry(key: key, value: value, type: type)
            }
            .environment(\.phantomTheme, theme)
        }
        .sheet(item: $viewModel.editingEntry) { entry in
            PhantomUserDefaultsInlineEditView(
                key: entry.key,
                currentValue: entry.displayValue,
                typeLabel: entry.typeLabel
            ) { newValue in
                viewModel.updateValue(for: entry.key, newValue: newValue, type: entry.typeLabel)
            }
            .environment(\.phantomTheme, theme)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.onBackgroundVariant)
            TextField("Search by key...", text: $viewModel.searchText)
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

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(PhantomUserDefaultsViewModel.GroupFilter.allCases, id: \.self) { group in
                Button(action: { viewModel.selectGroup(group) }) {
                    Text(group.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(viewModel.selectedGroup == group ? theme.onPrimary : theme.onBackground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(viewModel.selectedGroup == group ? theme.primary : theme.surface)
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.filteredEntries) { entry in
                    entryRow(entry)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    private func entryRow(_ entry: PhantomUserDefaultsViewModel.UserDefaultsEntry) -> some View {
        let isEditable = entry.typeLabel == "String" || entry.typeLabel == "Int" || entry.typeLabel == "Double"
        return Button(action: {
            guard isEditable else { return }
            viewModel.startEditing(entry)
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.key)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(theme.onBackground)
                        .lineLimit(1)
                    Spacer()
                    if isEditable {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundStyle(theme.onBackgroundVariant)
                    }
                    Text(entry.typeLabel)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(theme.primary.opacity(0.15)))
                }
                if entry.boolValue != nil {
                    Toggle(isOn: Binding(
                        get: { entry.boolValue ?? false },
                        set: { _ in viewModel.toggleBool(for: entry) }
                    )) {
                        Text(entry.displayValue)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(theme.onBackgroundVariant)
                    }
                    .tint(theme.primary)
                } else {
                    Text(entry.displayValue)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(theme.onBackgroundVariant)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                UIPasteboard.general.string = entry.displayValue
            } label: {
                Label("Copy Value", systemImage: "doc.on.doc")
            }
            Button {
                UIPasteboard.general.string = entry.key
            } label: {
                Label("Copy Key", systemImage: "doc.on.doc")
            }
            if isEditable {
                Button {
                    viewModel.startEditing(entry)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
            Button(role: .destructive) {
                viewModel.deleteKey(entry.key)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct PhantomUserDefaultsInlineEditView: View {

    @Environment(\.phantomTheme) private var theme
    @Environment(\.presentationMode) private var presentationMode

    let key: String
    let currentValue: String
    let typeLabel: String
    let onSave: (String) -> Void

    @State private var editedValue: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Key")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(theme.onBackgroundVariant)
                        Text(key)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(theme.onBackground)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Value")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(theme.onBackgroundVariant)
                            Spacer()
                            Text(typeLabel)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(theme.primary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 4).fill(theme.primary.opacity(0.15)))
                        }
                        TextField("Enter value", text: $editedValue)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundStyle(theme.onBackground)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
                            .disableAutocorrection(true)
                            .keyboardType(typeLabel == "Int" || typeLabel == "Double" ? .decimalPad : .default)
                    }
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundStyle(theme.onBackgroundVariant)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(editedValue)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.primary)
                }
            }
        }
        .onAppear { editedValue = currentValue }
    }
}
