import SwiftUI

struct CanvasSizeSheet: View {
    let foreground: PaletteColor
    let background: PaletteColor
    let session: EditorSession
    let finish: (CanvasSizeOptions?) -> Void
    @State private var draft: CanvasSizeDraft
    @State private var anchor = 4
    @State private var extensionChoice = "Transparent"
    @State private var customColor = PaletteColor.white
    private let anchorNames = [L10n.text("Top left"), L10n.text("Top center"), L10n.text("Top right"), L10n.text("Middle left"), L10n.text("Center"), L10n.text("Middle right"), L10n.text("Bottom left"), L10n.text("Bottom center"), L10n.text("Bottom right")]

    init(document: CanvasDocument, session: EditorSession, finish: @escaping (CanvasSizeOptions?) -> Void) {
        self.foreground = session.foregroundColor
        self.background = session.backgroundColor
        self.session = session
        self.finish = finish
        _draft = State(initialValue: CanvasSizeDraft(width: document.width, height: document.height, resolution: document.resolution))
    }

    private func dimension(_ widthAxis: Bool) -> Binding<Double> {
        Binding(get: { draft.displayed(widthAxis: widthAxis) }, set: { draft.set($0, widthAxis: widthAxis) })
    }
    private func scrubRange(_ widthAxis: Bool) -> ClosedRange<Double> {
        let original = Double(widthAxis ? draft.originalWidth : draft.originalHeight)
        let other = Double(widthAxis ? draft.originalHeight : draft.originalWidth)
        let lower = draft.locked ? max(1, original / other) : 1.0
        let upper = draft.locked ? min(30_000, 30_000 * original / other) : 30_000.0
        func displayed(_ pixels: Double) -> Double {
            let difference = pixels - (draft.relative ? original : 0)
            switch draft.unit {
            case .pixels: return difference
            case .percent: return difference / original * 100
            case .inches: return difference / draft.resolution
            case .centimeters: return difference / draft.resolution * 2.54
            }
        }
        return displayed(lower)...displayed(upper)
    }
    private func scrubSensitivity(_ widthAxis: Bool) -> Double {
        switch draft.unit {
        case .pixels: return 1
        case .percent: return 100 / Double(widthAxis ? draft.originalWidth : draft.originalHeight)
        case .inches: return 1 / draft.resolution
        case .centimeters: return 2.54 / draft.resolution
        }
    }
    private func bytes(_ width: Int, _ height: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(width) * Int64(height) * 4, countStyle: .memory)
    }
    private var fill: CanvasExtensionColor? {
        let color: NSColor
        switch extensionChoice {
        case "Transparent": return nil
        case "Black": color = .black
        case "Foreground": color = foreground.nsColor
        case "White": color = .white
        case "Background": color = background.nsColor
        default: color = customColor.nsColor
        }
        guard let rgb = color.usingColorSpace(.sRGB) else { return nil }
        return CanvasExtensionColor(red: rgb.redComponent, green: rgb.greenComponent, blue: rgb.blueComponent)
    }

    var body: some View { sheet.roundedControls() }
    @ViewBuilder private var sheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.text("Canvas Size")).font(.title2.bold())
            Text(L10n.text("Current: %@ × %@ pixels", String(describing: draft.originalWidth), String(describing: draft.originalHeight)))
            Text(L10n.text("%@ uncompressed RGBA canvas", String(describing: bytes(draft.originalWidth, draft.originalHeight))))
                .font(.callout).foregroundStyle(.secondary)
            Divider()
            Picker(L10n.text("Units"), selection: $draft.unit) {
                ForEach(CanvasUnit.allCases, id: \.self) { Text(L10n.text($0.rawValue)).tag($0) }
            }
            HStack {
                Text(L10n.text("Width")).frame(width: 60, alignment: .leading)
                    .scrubbable(sensitivity: scrubSensitivity(true), value: dimension(true), range: scrubRange(true), step: 1)
                TextField(L10n.text("Width"), value: dimension(true), format: .number.precision(.fractionLength(0...3)))
            }
            HStack {
                Text(L10n.text("Height")).frame(width: 60, alignment: .leading)
                    .scrubbable(sensitivity: scrubSensitivity(false), value: dimension(false), range: scrubRange(false), step: 1)
                TextField(L10n.text("Height"), value: dimension(false), format: .number.precision(.fractionLength(0...3)))
            }
            Toggle(L10n.text("Relative to current dimensions"), isOn: $draft.relative)
            Toggle(L10n.text("Lock original aspect ratio"), isOn: $draft.locked)
                .onChange(of: draft.locked) { _, locked in
                    if locked { draft.set(draft.displayed(widthAxis: true), widthAxis: true) }
                }
            if draft.valid {
                Text(L10n.text("New: %@ × %@ pixels · %@ uncompressed", String(describing: Int(draft.width.rounded())), String(describing: Int(draft.height.rounded())), String(describing: bytes(Int(draft.width.rounded()), Int(draft.height.rounded())))))
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                Text(L10n.text("Final dimensions must be 1–%@ pixels per side.", String(describing: DocumentLimits.maxSide.formatted())))
                    .font(.callout).foregroundStyle(.orange)
            }
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.text("Anchor"))
                    Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                        ForEach(0..<3) { row in
                            GridRow {
                                ForEach(0..<3) { column in
                                    let index = row * 3 + column
                                    Button { anchor = index } label: {
                                        Image(systemName: index == anchor ? "circle.fill" : "circle")
                                            .frame(width: 25, height: 25)
                                    }
                                    .tint(index == anchor ? .accentColor : .secondary)
                                    .help(anchorNames[index]).accessibilityLabel(anchorNames[index])
                                    .accessibilityValue(index == anchor ? L10n.text("Selected") : "")
                                }
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(anchorNames[anchor]).font(.callout.bold())
                    Text(L10n.text("Keeps this point fixed. Artwork is not scaled; cropped content remains outside the canvas."))
                        .font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }.padding(.top, 28)
            }
            Picker(L10n.text("Canvas extension"), selection: $extensionChoice) {
                ForEach(["Transparent", "Foreground", "Background", "Black", "White", "Custom"], id: \.self) { Text(L10n.text($0)).tag($0) }
            }
            if extensionChoice == "Custom" {
                HStack(spacing: 8) {
                    Text(L10n.text("Extension color"))
                    DialogColorSwatch(title: L10n.text("Extension Color"), color: $customColor, session: session)
                        .help(L10n.text("Color for the added canvas"))
                }
            }
            HStack {
                Button(L10n.text("Cancel")) { DialogColorSwatch.closePicker(session); finish(nil) }.configuredNativeShortcut(.escape)
                Spacer()
                Button(L10n.text("OK")) {
                    guard draft.valid else { return }
                    DialogColorSwatch.closePicker(session)
                    finish(CanvasSizeOptions(width: Int(draft.width.rounded()), height: Int(draft.height.rounded()), anchor: anchor, fill: fill))
                }.configuredNativeShortcut(.return).disabled(!draft.valid)
            }
        }.textFieldStyle(.roundedBorder).padding(24).frame(width: 450)
    }
}
