import SwiftUI

struct PhantomUserDefaultsEditView: View {

    @Environment(\.phantomTheme) private var theme
    @Environment(\.presentationMode) private var presentationMode

    let onSave: (String, String, String) -> Void

    @State private var key = ""
    @State private var value = ""
    @State private var selectedType = "String"

    private let types = ["String", "Int", "Double", "Bool"]

    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    fieldSection("Key", text: $key, placeholder: "Enter key")
                    if selectedType == "Bool" {
                        boolPicker
                    } else {
                        fieldSection("Value", text: $value, placeholder: "Enter value")
                    }
                    typePicker
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundStyle(theme.onBackgroundVariant)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        guard !key.isEmpty else { return }
                        onSave(key, value, selectedType)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(key.isEmpty ? theme.onBackgroundVariant : theme.primary)
                    .disabled(key.isEmpty)
                }
            }
        }
    }

    private func fieldSection(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(theme.onBackgroundVariant)
            TextField(placeholder, text: text)
                .font(.system(size: 14))
                .foregroundStyle(theme.onBackground)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
                .disableAutocorrection(true)
        }
    }

    private var boolPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Value")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(theme.onBackgroundVariant)
            Picker("", selection: $value) {
                Text("true").tag("true")
                Text("false").tag("false")
            }
            .pickerStyle(.segmented)
            .onAppear { if value.isEmpty { value = "true" } }
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Type")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(theme.onBackgroundVariant)
            HStack(spacing: 8) {
                ForEach(types, id: \.self) { type in
                    Button(action: { selectedType = type }) {
                        Text(type)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(selectedType == type ? theme.onPrimary : theme.onBackground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedType == type ? theme.primary : theme.surface)
                            )
                    }
                }
                Spacer()
            }
        }
    }
}
