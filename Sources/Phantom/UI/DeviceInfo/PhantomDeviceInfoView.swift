import SwiftUI

struct PhantomDeviceInfoView: View {

    @Environment(\.phantomTheme) private var theme
    @StateObject private var viewModel = PhantomDeviceInfoViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(PhantomDeviceInfoViewModel.InfoSection.allCases, id: \.self) { section in
                    sectionView(section)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Device Info")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionView(_ section: PhantomDeviceInfoViewModel.InfoSection) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(section.rawValue)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(theme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            ForEach(viewModel.items(for: section)) { item in
                infoRow(item)
                if item.id != viewModel.items(for: section).last?.id {
                    Divider().overlay(theme.outlineVariant).padding(.horizontal, 12)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.surface))
    }

    private func infoRow(_ item: PhantomDeviceInfoViewModel.InfoItem) -> some View {
        Button(action: { viewModel.copyValue(item) }) {
            HStack {
                Text(item.label)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.onBackgroundVariant)
                Spacer()
                if viewModel.copiedItemId == item.id {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(theme.success)
                } else {
                    Text(item.value)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(theme.onBackground)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
