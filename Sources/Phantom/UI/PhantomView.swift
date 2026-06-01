import SwiftUI

public struct PhantomView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.phantomTheme) private var theme

    public init() {
        Self.configureNavigationBarAppearance(theme: Phantom.theme)
    }

    public var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(Phantom.features.enumerated()), id: \.offset) { _, feature in
                            phantomRow(feature.title, icon: feature.icon, destination: feature.destinationView)
                        }
                        ForEach(Phantom.customEntries) { entry in
                            customRow(entry)
                        }
                    }
                }
            }
            .navigationTitle("Phantom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(theme.onBackgroundVariant)
                            .padding(8)
                            .background(Circle().fill(theme.surface))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .environment(\.phantomTheme, Phantom.theme)
    }

    private static func configureNavigationBarAppearance(theme: PhantomTheme) {
        let titleColor = UIColor(theme.onBackground)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(theme.background)
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
        let backImage = UIImage(systemName: "chevron.left")?
            .withTintColor(titleColor, renderingMode: .alwaysOriginal)
        appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: titleColor]
        buttonAppearance.normal.backgroundImage = UIImage()
        appearance.buttonAppearance = buttonAppearance
        appearance.doneButtonAppearance = buttonAppearance
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = titleColor
        let selectedAttrs = [NSAttributedString.Key.foregroundColor: UIColor(theme.background)]
        let normalAttrs = [NSAttributedString.Key.foregroundColor: titleColor]
        UISegmentedControl.appearance().selectedSegmentTintColor = titleColor
        UISegmentedControl.appearance().setTitleTextAttributes(selectedAttrs, for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes(normalAttrs, for: .normal)
        UISegmentedControl.appearance().backgroundColor = UIColor(theme.inputBackground)
    }

    @ViewBuilder
    private func customRow(_ entry: PhantomCustomEntry) -> some View {
        Button(action: entry.action) {
            HStack(spacing: 12) {
                Image(systemName: entry.icon)
                    .foregroundColor(theme.primary)
                    .frame(width: 24)
                Text(entry.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.onBackground)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.onBackgroundVariant)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
        Divider().overlay(theme.outlineVariant)
    }

    @ViewBuilder
    private func phantomRow<Destination: View>(_ title: String, icon: String, destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(theme.primary)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.onBackground)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.onBackgroundVariant)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
        Divider().overlay(theme.outlineVariant)
    }
}
