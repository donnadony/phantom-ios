import SwiftUI

struct DesignSystemView: View {

    @Environment(\.presentationMode) private var presentationMode

    private let colors: [(String, Color)] = [
        ("Primary", .blue),
        ("Secondary", .purple),
        ("Success", .green),
        ("Warning", .orange),
        ("Error", .red),
        ("Info", .cyan)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    colorsSection
                    typographySection
                    buttonsSection
                }
                .padding(16)
            }
            .navigationTitle("Design System")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }

    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Colors")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(colors, id: \.0) { name, color in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                            .frame(height: 48)
                        Text(name)
                            .font(.caption)
                    }
                }
            }
        }
    }

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Typography")
                .font(.headline)
            Group {
                Text("Large Title").font(.largeTitle)
                Text("Title").font(.title)
                Text("Headline").font(.headline)
                Text("Body").font(.body)
                Text("Caption").font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
        }
    }

    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Buttons")
                .font(.headline)
            HStack(spacing: 12) {
                Button("Primary") {}
                    .buttonStyle(.borderedProminent)
                Button("Secondary") {}
                    .buttonStyle(.bordered)
                Button("Destructive") {}
                    .foregroundColor(.red)
            }
        }
    }
}
