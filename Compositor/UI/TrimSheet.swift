import SwiftUI

struct TrimSheet: View {
    let finish: (TrimOptions?) -> Void
    @State private var basedOn: TrimBasedOn = .transparentPixels
    @State private var trimTop: Bool = true
    @State private var trimBottom: Bool = true
    @State private var trimLeft: Bool = true
    @State private var trimRight: Bool = true

    var body: some View { sheet.roundedControls() }

    @ViewBuilder private var sheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.text("Trim")).font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("Based On")).font(.headline)
                Picker("", selection: $basedOn) {
                    ForEach(TrimBasedOn.allCases) { option in
                        Text(L10n.text(option.rawValue)).tag(option)
                    }
                }
                .labelsHidden()
                .pickerStyle(.radioGroup)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("Trim Away")).font(.headline)
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 8) {
                    GridRow {
                        Toggle(L10n.text("Top"), isOn: $trimTop)
                        Toggle(L10n.text("Bottom"), isOn: $trimBottom)
                    }
                    GridRow {
                        Toggle(L10n.text("Left"), isOn: $trimLeft)
                        Toggle(L10n.text("Right"), isOn: $trimRight)
                    }
                }
            }

            Divider()

            HStack {
                Button(L10n.text("Cancel")) { finish(nil) }
                    .configuredNativeShortcut(.escape)
                Spacer()
                Button(L10n.text("OK")) {
                    let options = TrimOptions(
                        basedOn: basedOn,
                        top: trimTop,
                        bottom: trimBottom,
                        left: trimLeft,
                        right: trimRight
                    )
                    finish(options)
                }
                .configuredNativeShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(!trimTop && !trimBottom && !trimLeft && !trimRight)
            }
        }
        .padding(24)
        .frame(width: 320)
    }
}
