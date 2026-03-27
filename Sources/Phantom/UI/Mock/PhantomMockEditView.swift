import SwiftUI

struct PhantomMockEditView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.phantomTheme) private var theme
    @StateObject private var viewModel: PhantomMockEditViewModel

    private let onSave: (PhantomMockRule) -> Void

    init(existingRule: PhantomMockRule? = nil, onSave: @escaping (PhantomMockRule) -> Void) {
        _viewModel = StateObject(wrappedValue: PhantomMockEditViewModel(existingRule: existingRule))
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    fieldSection("Description", text: $viewModel.ruleDescription, placeholder: "e.g. Empty response")
                    fieldSection("URL Pattern (partial match)", text: $viewModel.urlPattern, placeholder: "e.g. /v1/users")
                    responsesSection()
                    deleteButton()
                }
                .padding(16)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .font(.system(size: 14))
                        .foregroundStyle(theme.onBackgroundVariant)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveRule() }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(viewModel.isValid ? theme.primary : theme.onBackgroundVariant)
                        .disabled(!viewModel.isValid)
                }
            }
            .sheet(item: $viewModel.responseEditorItem) { item in
                PhantomMockResponseEditView(
                    existingResponse: item.response,
                    responseIndex: item.response.flatMap { viewModel.responseIndex(for: $0) } ?? (viewModel.responses.count + 1),
                    onSave: { viewModel.handleResponseSave($0) }
                )
                .environment(\.phantomTheme, theme)
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private func fieldSection(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.onBackground)
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundStyle(theme.onBackground)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
        }
    }

    @ViewBuilder
    private func methodPicker(selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HTTP Method")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.onBackground)
            HStack(spacing: 8) {
                ForEach(viewModel.httpMethods, id: \.self) { method in
                    Button(action: { selection.wrappedValue = method }) {
                        Text(method)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(selection.wrappedValue == method ? theme.onPrimary : theme.onBackground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selection.wrappedValue == method ? theme.primary : theme.surface)
                            )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func responsesSection() -> some View {
        if viewModel.hasMultipleResponses {
            multiResponseList()
        } else {
            inlineResponseEditor()
        }
    }

    @ViewBuilder
    private func inlineResponseEditor() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            methodPicker(selection: $viewModel.httpMethod)
            statusCodePicker(selection: $viewModel.inlineStatusCode)
            inlineBodyEditor()
            Button(action: { viewModel.addResponse() }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add another response")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(theme.primary)
            }
        }
    }

    @ViewBuilder
    private func inlineBodyEditor() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Response Body (JSON)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.onBackground)
                Spacer()
                Button(action: { viewModel.pasteInlineBody() }) {
                    Text("Paste")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                }
                Button(action: { viewModel.formatInlineJson() }) {
                    Text("Format")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                }
            }
            PhantomThemedTextEditor(text: $viewModel.inlineResponseBody)
        }
    }

    @ViewBuilder
    private func multiResponseList() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Responses (\(viewModel.responses.count))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.onBackground)
                Spacer()
                Button(action: { viewModel.responseEditorItem = .add }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(theme.primary)
                }
            }
            ForEach(viewModel.responses) { response in
                responseRow(response)
            }
        }
    }

    @ViewBuilder
    private func responseRow(_ response: PhantomMockResponse) -> some View {
        let isActive = viewModel.isActiveResponse(response)
        HStack(spacing: 10) {
            Button(action: { viewModel.setActiveResponse(response.id) }) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isActive ? theme.primary : theme.onBackgroundVariant)
                    .font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(response.httpMethod)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.onPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(viewModel.methodColor(response.httpMethod, theme: theme)))
                    Text(response.name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.onBackground)
                        .lineLimit(1)
                    if isActive {
                        Text("ACTIVE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(theme.onPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(theme.primary))
                    }
                }
                Text("Status: \(response.statusCode)")
                    .font(.system(size: 12))
                    .foregroundStyle(viewModel.statusColor(response.statusCode, theme: theme))
            }
            Spacer()
            Button(action: { viewModel.editResponse(response) }) {
                Image(systemName: "pencil")
                    .foregroundStyle(theme.primary)
                    .font(.system(size: 14))
            }
            Button(action: { viewModel.deleteResponse(response) }) {
                Image(systemName: "trash")
                    .foregroundStyle(theme.error)
                    .font(.system(size: 14))
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(isActive ? theme.primary.opacity(0.08) : theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isActive ? theme.primary : .clear, lineWidth: 1))
    }

    @ViewBuilder
    private func deleteButton() -> some View {
        if viewModel.isEditing {
            Button(action: {
                viewModel.deleteExistingRule()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Delete Rule")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 8).fill(theme.error.opacity(0.1)))
            }
        }
    }

    private func saveRule() {
        guard let rule = viewModel.buildRule() else { return }
        onSave(rule)
    }
}

// MARK: - Status Code Picker

struct PhantomStatusCodePicker: View {

    @Binding var selectedCode: Int
    @Environment(\.phantomTheme) private var theme
    @State private var isExpanded = false
    @State private var searchText = ""

    private var allEntries: [PhantomHTTPStatusCode.Entry] {
        PhantomHTTPStatusCode.grouped.flatMap(\.entries)
    }

    private var filteredCommon: [PhantomHTTPStatusCode.Entry] {
        guard searchText.isNotEmpty else { return PhantomHTTPStatusCode.common }
        return PhantomHTTPStatusCode.common.filter { matches($0) }
    }

    private var filteredGroups: [PhantomHTTPStatusCode.Group] {
        guard searchText.isNotEmpty else { return PhantomHTTPStatusCode.grouped }
        return PhantomHTTPStatusCode.grouped.compactMap { group in
            let filtered = group.entries.filter { matches($0) }
            guard filtered.isNotEmpty else { return nil }
            return PhantomHTTPStatusCode.Group(title: group.title, entries: filtered)
        }
    }

    private var hasResults: Bool {
        filteredCommon.isNotEmpty || filteredGroups.isNotEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Status Code")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.onBackground)
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack {
                    Text(statusLabel(for: selectedCode))
                        .font(.system(size: 14))
                        .foregroundStyle(theme.onBackground)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.onBackgroundVariant)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
            }
            if isExpanded {
                pickerContent()
            }
        }
    }

    @ViewBuilder
    private func pickerContent() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            searchField()
            Divider().overlay(theme.outlineVariant)
            if hasResults {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if filteredCommon.isNotEmpty {
                            sectionHeader("Common")
                            ForEach(filteredCommon) { entry in
                                statusRow(entry)
                            }
                        }
                        ForEach(filteredGroups) { group in
                            Divider().overlay(theme.outlineVariant)
                            sectionHeader(group.title)
                            ForEach(group.entries) { entry in
                                statusRow(entry)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
            } else {
                Text("No matching status codes")
                    .font(.system(size: 13))
                    .foregroundStyle(theme.onBackgroundVariant)
                    .padding(12)
            }
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.outlineVariant, lineWidth: 1))
    }

    @ViewBuilder
    private func searchField() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(theme.onBackgroundVariant)
            TextField("Search by code or name", text: $searchText)
                .font(.system(size: 13))
                .foregroundStyle(theme.onBackground)
                .disableAutocorrection(true)
        }
        .padding(12)
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(theme.onBackgroundVariant)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    @ViewBuilder
    private func statusRow(_ entry: PhantomHTTPStatusCode.Entry) -> some View {
        Button(action: {
            selectedCode = entry.code
            searchText = ""
            withAnimation { isExpanded = false }
        }) {
            HStack {
                Text("\(entry.code) - \(entry.label)")
                    .font(.system(size: 13))
                    .foregroundStyle(selectedCode == entry.code ? theme.primary : theme.onBackground)
                Spacer()
                if selectedCode == entry.code {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selectedCode == entry.code ? theme.primary.opacity(0.08) : .clear)
        }
    }

    private func matches(_ entry: PhantomHTTPStatusCode.Entry) -> Bool {
        let query = searchText.lowercased()
        return String(entry.code).contains(query) || entry.label.lowercased().contains(query)
    }

    private func statusLabel(for code: Int) -> String {
        if let entry = allEntries.first(where: { $0.code == code }) {
            return "\(code) - \(entry.label)"
        }
        return "\(code)"
    }
}

private extension PhantomMockEditView {

    @ViewBuilder
    func statusCodePicker(selection: Binding<Int>) -> some View {
        PhantomStatusCodePicker(selectedCode: selection)
    }
}

// MARK: - Response Edit View

struct PhantomMockResponseEditView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.phantomTheme) private var theme
    @State private var name: String
    @State private var httpMethod: String
    @State private var statusCode: Int
    @State private var responseBody: String

    private let existingResponse: PhantomMockResponse?
    private let responseIndex: Int
    private let onSave: (PhantomMockResponse) -> Void
    private let httpMethods = ["ANY", "GET", "POST", "PUT", "DELETE"]

    init(existingResponse: PhantomMockResponse? = nil, responseIndex: Int, onSave: @escaping (PhantomMockResponse) -> Void) {
        self.existingResponse = existingResponse
        self.responseIndex = responseIndex
        self.onSave = onSave
        _name = State(initialValue: existingResponse?.name ?? "Response \(responseIndex)")
        _httpMethod = State(initialValue: existingResponse?.httpMethod ?? "ANY")
        _statusCode = State(initialValue: existingResponse?.statusCode ?? 200)
        _responseBody = State(initialValue: existingResponse?.responseBody ?? "{\n  \n}")
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    fieldSection("Name", text: $name, placeholder: "e.g. Success response")
                    methodPickerSection()
                    PhantomStatusCodePicker(selectedCode: $statusCode)
                    responseBodyEditor()
                }
                .padding(16)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle(existingResponse == nil ? "New Response" : "Edit Response")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .font(.system(size: 14))
                        .foregroundStyle(theme.onBackgroundVariant)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveResponse() }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isValid ? theme.primary : theme.onBackgroundVariant)
                        .disabled(!isValid)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private func fieldSection(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.onBackground)
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundStyle(theme.onBackground)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
        }
    }

    @ViewBuilder
    private func methodPickerSection() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HTTP Method")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.onBackground)
            HStack(spacing: 8) {
                ForEach(httpMethods, id: \.self) { method in
                    Button(action: { httpMethod = method }) {
                        Text(method)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(httpMethod == method ? theme.onPrimary : theme.onBackground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(httpMethod == method ? theme.primary : theme.surface)
                            )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func responseBodyEditor() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Response Body (JSON)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.onBackground)
                Spacer()
                Button(action: pasteFromClipboard) {
                    Text("Paste")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                }
                Button(action: formatJson) {
                    Text("Format")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.primary)
                }
            }
            PhantomThemedTextEditor(text: $responseBody)
        }
    }

    private func saveResponse() {
        guard isValid else { return }
        let response = PhantomMockResponse(
            id: existingResponse?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            httpMethod: httpMethod,
            statusCode: statusCode,
            responseBody: responseBody
        )
        onSave(response)
        presentationMode.wrappedValue.dismiss()
    }

    private func pasteFromClipboard() {
        guard let content = UIPasteboard.general.string else { return }
        responseBody = content
        formatJson()
    }

    private func formatJson() {
        guard let data = responseBody.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
              let string = String(data: formatted, encoding: .utf8) else { return }
        responseBody = string
    }
}

// MARK: - Response Editor Item

struct ResponseEditorItem: Identifiable {
    let id: UUID
    let response: PhantomMockResponse?

    static var add: ResponseEditorItem {
        ResponseEditorItem(id: UUID(), response: nil)
    }

    static func edit(_ response: PhantomMockResponse) -> ResponseEditorItem {
        ResponseEditorItem(id: response.id, response: response)
    }
}

// MARK: - Themed TextEditor

struct PhantomThemedTextEditor: View {

    @Binding var text: String
    @Environment(\.phantomTheme) private var theme

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 12, weight: .regular, design: .monospaced))
            .foregroundStyle(theme.onBackground)
            .phantomHideScrollBackground()
            .frame(minHeight: 200)
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(theme.inputBackground))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.outlineVariant, lineWidth: 1))
    }
}

private extension View {

    @ViewBuilder
    func phantomHideScrollBackground() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self.onAppear { UITextView.appearance().backgroundColor = .clear }
        }
    }
}
