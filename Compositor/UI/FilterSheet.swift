import AppKit
import SwiftUI

/// The open filter's panel: its settings, Preview, and Cancel / OK.
struct FilterSheet: View {
    @Bindable var session: EditorSession
    private var edit: FilterEdit? { session.filterEdit }
    private var settings: FilterSettings { edit?.settings ?? FilterSettings() }
    private func update(_ change: (inout FilterSettings) -> Void) {
        var value = settings
        change(&value)
        session.updateFilter(value, preview: edit?.preview ?? true)
    }

    private var isCameraRaw: Bool { edit?.kind == .cameraRaw }
    /// The widest slider title in the panel, so every slider starts and ends in the same place.
    @State private var labelWidth: CGFloat = 60

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch edit?.kind ?? .gaussianBlur {
            case .curves:
                CurvesControls(settings: Binding(get: { settings.curves }, set: { new in update { $0.curves = new } }))
            case .exposure:
                control(L10n.text("Exposure"), \.exposure.exposure, range: ExposureSettings.exposureRange, unit: "", decimals: 2, logarithmic: false)
                control(L10n.text("Offset"), \.exposure.offset, range: ExposureSettings.offsetRange, unit: "", decimals: 4, logarithmic: false)
                control(L10n.text("Gamma"), \.exposure.gamma, range: ExposureSettings.gammaRange, unit: "", decimals: 2, logarithmic: true)
            case .gradientMap:
                GradientMapControls(settings: Binding(get: { settings.gradientMap }, set: { new in update { $0.gradientMap = new } }),
                                    pick: { session.openGradientMapColorPicker(highlights: $0) })
            case .blackWhite:
                // Each slider says how bright that family of colors becomes, as Photoshop's do.
                control(L10n.text("Reds"), \.blackWhite.reds, range: BlackWhiteSettings.range, unit: "%", decimals: 0, logarithmic: false, track: .luminance(0))
                control(L10n.text("Yellows"), \.blackWhite.yellows, range: BlackWhiteSettings.range, unit: "%", decimals: 0, logarithmic: false, track: .luminance(60))
                control(L10n.text("Greens"), \.blackWhite.greens, range: BlackWhiteSettings.range, unit: "%", decimals: 0, logarithmic: false, track: .luminance(120))
                control(L10n.text("Cyans"), \.blackWhite.cyans, range: BlackWhiteSettings.range, unit: "%", decimals: 0, logarithmic: false, track: .luminance(180))
                control(L10n.text("Blues"), \.blackWhite.blues, range: BlackWhiteSettings.range, unit: "%", decimals: 0, logarithmic: false, track: .luminance(240))
                control(L10n.text("Magentas"), \.blackWhite.magentas, range: BlackWhiteSettings.range, unit: "%", decimals: 0, logarithmic: false, track: .luminance(300))
                Toggle(L10n.text("Tint"), isOn: flag(\.blackWhite.tint))
                    .help(L10n.text("Color the result while keeping its tones, for a sepia or a cyanotype"))
                if settings.blackWhite.tint {
                    control(L10n.text("Hue"), \.blackWhite.tintHue, range: 0...360, unit: "°", decimals: 0, logarithmic: false, track: .plain)
                    control(L10n.text("Saturation"), \.blackWhite.tintSaturation, range: 0...100, unit: "%", decimals: 0, logarithmic: false,
                            track: .saturation(settings.blackWhite.tintHue))
                }
            case .cameraRaw:
                CameraRawControls(session: session)
                    .frame(maxHeight: .infinity, alignment: .top)
            case .colorBalance:
                Text(L10n.text("Shadows")).font(.headline)
                control(L10n.text("Cyan / Red"), \.colorBalance.shadowCyanRed, range: ColorBalanceSettings.range, unit: "", decimals: 0, logarithmic: false, track: Self.cyanRedTrack)
                control(L10n.text("Magenta / Green"), \.colorBalance.shadowMagentaGreen, range: ColorBalanceSettings.range, unit: "", decimals: 0, logarithmic: false, track: Self.magentaGreenTrack)
                control(L10n.text("Yellow / Blue"), \.colorBalance.shadowYellowBlue, range: ColorBalanceSettings.range, unit: "", decimals: 0, logarithmic: false, track: Self.yellowBlueTrack)
                Text(L10n.text("Midtones")).font(.headline)
                control(L10n.text("Cyan / Red"), \.colorBalance.midCyanRed, range: ColorBalanceSettings.range, unit: "", decimals: 0, logarithmic: false, track: Self.cyanRedTrack)
                control(L10n.text("Magenta / Green"), \.colorBalance.midMagentaGreen, range: ColorBalanceSettings.range, unit: "", decimals: 0, logarithmic: false, track: Self.magentaGreenTrack)
                control(L10n.text("Yellow / Blue"), \.colorBalance.midYellowBlue, range: ColorBalanceSettings.range, unit: "", decimals: 0, logarithmic: false, track: Self.yellowBlueTrack)
                Text(L10n.text("Highlights")).font(.headline)
                control(L10n.text("Cyan / Red"), \.colorBalance.highlightCyanRed, range: ColorBalanceSettings.range, unit: "", decimals: 0, logarithmic: false, track: Self.cyanRedTrack)
                control(L10n.text("Magenta / Green"), \.colorBalance.highlightMagentaGreen, range: ColorBalanceSettings.range, unit: "", decimals: 0, logarithmic: false, track: Self.magentaGreenTrack)
                control(L10n.text("Yellow / Blue"), \.colorBalance.highlightYellowBlue, range: ColorBalanceSettings.range, unit: "", decimals: 0, logarithmic: false, track: Self.yellowBlueTrack)
                Toggle(L10n.text("Preserve Luminosity"), isOn: flag(\.colorBalance.preserveLuminosity))
                    .help(L10n.text("Put each pixel's brightness back afterwards, so only the color moves"))
            case .grain:
                control(L10n.text("Amount"), \.grain.amount, range: GrainSettings.amountRange, unit: "", decimals: 0, logarithmic: false)
                control(L10n.text("Size"), \.grain.size, range: GrainSettings.sizeRange, unit: "px", decimals: 1, logarithmic: true)
                control(L10n.text("Roughness"), \.grain.roughness, range: GrainSettings.roughnessRange, unit: "", decimals: 0, logarithmic: false)
            case .removeBackground:
                Text(L10n.text("Hide the background behind a layer mask, keeping the foreground subjects. The pixels stay, so the background can be painted back at any time."))
                    .fixedSize(horizontal: false, vertical: true)
                Picker(L10n.text("Quality"), selection: Binding(get: { settings.backgroundQuality },
                                                     set: { new in update { $0.backgroundQuality = new } })) {
                    ForEach(BackgroundQuality.allCases, id: \.self) { Text(L10n.text($0.rawValue)).tag($0) }
                }
                .pickerStyle(.segmented).labelsHidden()
                .help(L10n.text("Basic is quick; Advanced refines the mask against the layer's own detail, for hair and fur"))
                if settings.backgroundQuality == .advanced {
                    control(L10n.text("Refine"), \.refineEdges, range: 0...40, unit: "px", decimals: 0, logarithmic: false)
                        .help(L10n.text("Pull the mask onto the image's own edges, which recovers hair and fur"))
                    control(L10n.text("Contrast"), \.matteContrast, range: 0...100, unit: "%", decimals: 0, logarithmic: false)
                        .help(L10n.text("Clear the haze that leaves background showing through thin areas"))
                    control(L10n.text("Shift Edge"), \.shiftEdge, range: -10...10, unit: "px", decimals: 0, logarithmic: false)
                        .help(L10n.text("Shrink the mask to drop the rim of background color around the subject, or grow it"))
                }
            case .contentAwareFill:
                Text(L10n.text("Fill the selection using surrounding pixels from this layer."))
                    .fixedSize(horizontal: false, vertical: true)
            case .gaussianBlur:
                control(L10n.text("Radius"), \.radius, range: 0.1...250, unit: "px", decimals: 1, logarithmic: true)
                Toggle(L10n.text("Preserve Transparency"), isOn: flag(\.preserveTransparency))
                    .help(L10n.text("Blur only the colors, keeping the layer's outline and transparency as they are"))
            case .motionBlur:
                control(L10n.text("Angle"), \.angle, range: -90...90, unit: "°", decimals: 0, logarithmic: false)
                control(L10n.text("Distance"), \.distance, range: 1...2000, unit: "px", decimals: 0, logarithmic: true)
            case .addNoise:
                control(L10n.text("Amount"), \.amount, range: 0.1...400, unit: "%", decimals: 1, logarithmic: true)
                HStack(spacing: 10) {
                    Text(L10n.text("Distribution"))
                    Picker(L10n.text("Distribution"), selection: flag(\.gaussian)) {
                        Text(L10n.text("Uniform")).tag(false)
                        Text(L10n.text("Gaussian")).tag(true)
                    }
                    .pickerStyle(.segmented).labelsHidden()
                }
                Toggle(L10n.text("Monochromatic"), isOn: flag(\.monochromatic))
            case .dither:
                ditherControls
            case .scanlines:
                scanlinesControls
            case .vignette:
                HStack(spacing: 8) {
                    Text(L10n.text("Color")).frame(width: 95, alignment: .leading)
                    Button { session.openVignetteColorPicker() } label: {
                        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
                        shape.fill(Color(.sRGB, red: settings.vignetteColor.red,
                                         green: settings.vignetteColor.green, blue: settings.vignetteColor.blue))
                            .overlay { shape.inset(by: 1).strokeBorder(.white, lineWidth: 1.5) }
                            .overlay { shape.strokeBorder(.black, lineWidth: 1) }
                            .frame(width: 24, height: 24)
                            .contentShape(shape)
                    }
                    .buttonStyle(.plain)
                    .help(L10n.text("Choose the vignette color"))
                    Spacer()
                }
                control(L10n.text("Amount"), \.vignetteAmount, range: 0...100, unit: "%", decimals: 0, logarithmic: false)
                    .help(L10n.text("Blend the chosen color into the edges while keeping the center unchanged"))
                control(L10n.text("Midpoint"), \.vignetteMidpoint, range: 0...100, unit: "%", decimals: 0, logarithmic: false)
                control(L10n.text("Roundness"), \.vignetteRoundness, range: -100...100, unit: "", decimals: 0, logarithmic: false)
                control(L10n.text("Feather"), \.vignetteFeather, range: 0...100, unit: "%", decimals: 0, logarithmic: false)
                control(L10n.text("Highlights"), \.vignetteHighlights, range: 0...100, unit: "%", decimals: 0, logarithmic: false)
                    .help(L10n.text("Protect bright areas near the edge"))
            case .bloomGlow:
                control(L10n.text("Amount"), \.bloomAmount, range: 0...100, unit: "%", decimals: 0, logarithmic: false)
                control(L10n.text("Radius"), \.bloomRadius, range: 1...150, unit: "px", decimals: 0, logarithmic: true)
            case .tonalContrast:
                control(L10n.text("Amount"), \.tonalAmount, range: 0...100, unit: "%", decimals: 0, logarithmic: false)
                control(L10n.text("Shadows"), \.tonalShadows, range: -100...100, unit: "%", decimals: 0, logarithmic: false)
                control(L10n.text("Midtones"), \.tonalMidtones, range: -100...100, unit: "%", decimals: 0, logarithmic: false)
                control(L10n.text("Highlights"), \.tonalHighlights, range: -100...100, unit: "%", decimals: 0, logarithmic: false)
                control(L10n.text("Radius"), \.tonalRadius, range: 1...100, unit: "px", decimals: 0, logarithmic: true)
            case .lensCorrection:
                control(L10n.text("Remove Distortion"), \.distortion, range: -100...100, unit: "", decimals: 0, logarithmic: false)
                Text(L10n.text("Positive straightens lines that bow outward (barrel); negative, lines that bow inward (pincushion)."))
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Toggle(L10n.text("Preview"), isOn: Binding(get: { edit?.preview ?? true },
                                            set: { session.updateFilter(settings, preview: $0) }))
            if let error = edit?.previewError {
                Text(error).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
            }
            if session.adjustmentOriginal == nil && session.selection != nil {
                Text(L10n.text("Limited to the selection")).font(.callout).foregroundStyle(.secondary)
            }
            Divider()
            HStack {
                Button(L10n.text("Cancel")) { session.cancelFilter() }.configuredNativeShortcut(.escape)
                Spacer()
                // While the preview is being worked out (Remove Background's mask, Content-Aware Fill) OK waits, so
                // the panel says what it is waiting for rather than showing a disabled button and nothing else.
                // Only the slow filters say so: a quick preview (Dither, a blur) toggling this at every slider step would
                // make the panel flicker as it grows and shrinks.
                if edit?.committing == true || (edit?.preparing == true && edit?.kind.isAutomatic == true) {
                    ProgressView().controlSize(.small)
                    Text(edit?.committing == true ? L10n.text("Applying…") : L10n.text("Working…"))
                        .font(.callout).foregroundStyle(.secondary)
                }
                Button(L10n.text("OK")) { Task { await session.commitFilter() } }
                    .configuredNativeShortcut(.return).buttonStyle(.borderedProminent)
                    .disabled(edit?.kind.isAutomatic == true && (edit?.preparing == true || edit?.previewError != nil))
            }
        }
        .onPreferenceChange(LabelWidthKey.self) { labelWidth = max(60, $0) }
        .padding(24)
        .frame(width: isCameraRaw ? FloatingPanelController.dockedWidth : 380)
        .frame(maxHeight: isCameraRaw ? .infinity : nil, alignment: .top)
        .fixedSize(horizontal: false, vertical: !isCameraRaw)

        .disabled(edit?.committing == true)
        // Filter colors preview live while the app's color picker is open.
        .onChange(of: session.colorPicker?.color) { _, _ in
            session.previewGradientMapColor()
            session.previewVignetteColor()
            session.previewDitherColor()
        }
    }

    @ViewBuilder private var ditherControls: some View {
        let dither = settings.dither
        Picker(L10n.text("Style"), selection: Binding(get: { dither.style }, set: { new in update { $0.dither.style = new } })) {
            ForEach(DitherStyle.groups.indices, id: \.self) { group in
                if group > 0 { Divider() }
                ForEach(DitherStyle.groups[group], id: \.self) { Text(L10n.text($0.rawValue)).tag($0) }
            }
        }
        if dither.style.usesPixelSize {
        control(L10n.text("Pixel Size"), \.dither.pixelSize, range: DitherSettings.pixelSizeRange, unit: "px", decimals: 0, logarithmic: false)
            .help(L10n.text("Make each dithered pixel this many pixels across, for a chunky old-screen look"))
        }
        if dither.style == .ascii {
            control(L10n.text("Text Size"), \.dither.textSize, range: DitherSettings.textSizeRange, unit: "px", decimals: 0, logarithmic: false)
                .help(L10n.text("The height of each line of characters"))
        }
        if dither.style.isHalftone {
            control(L10n.text("Cell Size"), \.dither.cellSize, range: DitherSettings.cellSizeRange, unit: "px", decimals: 0, logarithmic: false)
        }
        if dither.style.isHalftone {
            control(L10n.text("Angle"), \.dither.angle, range: -90...90, unit: "°", decimals: 0, logarithmic: false)
        }
        if dither.style == .ascii {
            HStack(spacing: 10) {
                Text(L10n.text("Characters"))
                TextField(L10n.text("Characters"), text: Binding(get: { dither.characters }, set: { new in update { $0.dither.characters = new } }))
                    .textFieldStyle(.roundedBorder).font(.body.monospaced())
            }
            .help(L10n.text("The characters to draw with, in any order: each spot gets the one whose ink best matches its tone"))
        }
        if dither.style.hasTones {
            control(L10n.text("Tones"), \.dither.levels, range: DitherSettings.levelsRange, unit: "", decimals: 0, logarithmic: false)
                .help(L10n.text("Tones per channel: 2 is pure black and white"))
        }
        if dither.style.diffuses {
            control(L10n.text("Diffusion"), \.dither.diffusion, range: 0...100, unit: "%", decimals: 0, logarithmic: false)
                .help(L10n.text("How much of each pixel's error spreads to its neighbors. Less gives flatter areas"))
        }
        control(L10n.text("Density"), \.dither.density, range: -100...100, unit: "", decimals: 0, logarithmic: false)
            .help(L10n.text("More ink (darker) or less before dithering"))
        control(L10n.text("Contrast"), \.dither.contrast, range: -100...100, unit: "", decimals: 0, logarithmic: false)
        // A menu, like Style: the three choices as segments are wider than the panel, which then flips between
        // squeezing the row and wrapping it, resizing itself at every slider step.
        Picker(L10n.text("Colors"), selection: Binding(get: { dither.colors }, set: { new in update { $0.dither.colors = new } })) {
            ForEach(DitherColors.allCases, id: \.self) { Text(L10n.text($0.rawValue)).tag($0) }
        }
        .fixedSize()
        if dither.colors == .twoColors {
            HStack(spacing: 8) {
                Text(L10n.text("Dark"))
                swatch(dither.dark, help: L10n.text("Choose the dark color")) { session.openDitherColorPicker(light: false) }
                Text(L10n.text("Light Color")).padding(.leading, 10)
                swatch(dither.light, help: L10n.text("Choose the light color")) { session.openDitherColorPicker(light: true) }
                Spacer()
            }
        }
        if dither.pixelSize > 1, dither.style.usesPixelSize {
            Picker(L10n.text("Pixel Shape"), selection: Binding(get: { dither.pixelShape }, set: { new in update { $0.dither.pixelShape = new } })) {
                ForEach(DitherPixelShape.allCases, id: \.self) { Text(L10n.text($0.rawValue)).tag($0) }
            }
            .fixedSize()
            .help(L10n.text("Draw each chunky pixel as a solid square, or as a round dot like a dot-matrix screen"))
        }
        if dither.style.drawsMarks {
            Toggle(L10n.text("Light on Dark"), isOn: flag(\.dither.lightOnDark))
                .help(L10n.text("Draw the marks for the light tones on the dark color, like a glowing screen"))
        }
    }

    @ViewBuilder private var scanlinesControls: some View {
        let lines = settings.scanlines
        control(L10n.text("Line Spacing"), \.scanlines.lineSpacing, range: ScanlinesSettings.lineSpacingRange, unit: "px", decimals: 0, logarithmic: false)
            .help(L10n.text("How far apart the screen's lines are"))
        control(L10n.text("Thickness"), \.scanlines.thickness, range: 5...100, unit: "%", decimals: 0, logarithmic: false)
            .help(L10n.text("How much of the gap a bright line fills; dimmer parts draw it thinner"))
        control(L10n.text("Glow"), \.scanlines.glow, range: 0...100, unit: "%", decimals: 0, logarithmic: false)
            .help(L10n.text("Light blooming around the lines, like a CRT's phosphors"))
        control(L10n.text("Dots"), \.scanlines.dots, range: 0...100, unit: "%", decimals: 0, logarithmic: false)
            .help(L10n.text("Break the lines into beads where the picture is darker than this, blending into solid lines where it's brighter"))
        control(L10n.text("Displace"), \.scanlines.displace, range: ScanlinesSettings.displaceRange, unit: "px", decimals: 0, logarithmic: false)
            .help(L10n.text("Lift the lines where the picture is bright, or lower them when negative, so they swell into its shapes"))
        control(L10n.text("Smoothness"), \.scanlines.smoothness, range: 0...100, unit: "%", decimals: 0, logarithmic: false)
            .help(L10n.text("How far the brightness is smoothed before it displaces the lines, from sharp ridges to rounded hills"))
        control(L10n.text("Threshold"), \.scanlines.threshold, range: 0...100, unit: "%", decimals: 0, logarithmic: false)
            .help(L10n.text("Draw no line where the picture is darker than this, leaving the screen dark"))
        control(L10n.text("Wobble"), \.scanlines.wobble, range: ScanlinesSettings.wobbleRange, unit: "px", decimals: 0, logarithmic: false)
            .help(L10n.text("Make the lines waver sideways down the screen, like a CRT losing sync"))
        control(L10n.text("Color Split"), \.scanlines.split, range: ScanlinesSettings.splitRange, unit: "px", decimals: 0, logarithmic: false)
            .help(L10n.text("Move the red and blue apart, for colored fringes on the lines"))
        control(L10n.text("Density"), \.scanlines.density, range: -100...100, unit: "", decimals: 0, logarithmic: false)
            .help(L10n.text("Darker or lighter before the lines are drawn"))
        control(L10n.text("Contrast"), \.scanlines.contrast, range: -100...100, unit: "", decimals: 0, logarithmic: false)
        control(L10n.text("Black Level"), \.scanlines.blackLevel, range: 0...100, unit: "%", decimals: 0, logarithmic: false)
            .help(L10n.text("How bright the lines are where the picture is black, so they show even over black"))
        Picker(L10n.text("Colors"), selection: Binding(get: { lines.colors }, set: { new in update { $0.scanlines.colors = new } })) {
            ForEach(DitherColors.allCases, id: \.self) { Text(L10n.text($0.rawValue)).tag($0) }
        }
        .fixedSize()
        if lines.colors == .twoColors {
            HStack(spacing: 8) {
                Text(L10n.text("Dark"))
                swatch(lines.dark, help: L10n.text("Choose the screen's color")) { session.openDitherColorPicker(light: false) }
                Text(L10n.text("Light Color")).padding(.leading, 10)
                swatch(lines.light, help: L10n.text("Choose the lines' color")) { session.openDitherColorPicker(light: true) }
                Spacer()
            }
        }
    }

    private func swatch(_ color: AdjustmentColor, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
            shape.fill(Color(.sRGB, red: color.red, green: color.green, blue: color.blue))
                .overlay { shape.inset(by: 1).strokeBorder(.white, lineWidth: 1.5) }
                .overlay { shape.strokeBorder(.black, lineWidth: 1) }
                .frame(width: 24, height: 24)
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func flag(_ key: WritableKeyPath<FilterSettings, Bool>) -> Binding<Bool> {
        Binding(get: { settings[keyPath: key] }, set: { value in update { $0[keyPath: key] = value } })
    }

    /// The setting put back to its filter's default, as a double-click on a colored slider does.
    static func resetting(_ key: WritableKeyPath<FilterSettings, Double>, in settings: FilterSettings) -> FilterSettings {
        var value = settings
        value[keyPath: key] = FilterSettings()[keyPath: key]
        return value
    }

    static let cyanRedTrack = CameraRawSliderTrack.opposing(NSColor(srgbRed: 0.10, green: 0.72, blue: 0.80, alpha: 1),
                                                            NSColor(srgbRed: 0.86, green: 0.18, blue: 0.20, alpha: 1))
    static let magentaGreenTrack = CameraRawSliderTrack.opposing(NSColor(srgbRed: 0.80, green: 0.22, blue: 0.70, alpha: 1),
                                                                 NSColor(srgbRed: 0.24, green: 0.70, blue: 0.30, alpha: 1))
    static let yellowBlueTrack = CameraRawSliderTrack.opposing(NSColor(srgbRed: 0.95, green: 0.82, blue: 0.18, alpha: 1),
                                                               NSColor(srgbRed: 0.22, green: 0.40, blue: 0.92, alpha: 1))

    /// A slider plus an exact field. Logarithmic sliders give the small values used most most of the travel.
    /// A colored track draws the slider as Camera Raw's, where a double-click on the title or knob resets it.
    private func control(_ title: String, _ key: WritableKeyPath<FilterSettings, Double>, range: ClosedRange<Double>,
                         unit: String, decimals: Int, logarithmic: Bool, track: CameraRawSliderTrack? = nil) -> some View {
        let step = pow(10, Double(decimals))
        let reset = { update { $0 = Self.resetting(key, in: $0) } }
        return HStack(spacing: 10) {
            Text(L10n.text(title)).fixedSize()
                .background(GeometryReader { Color.clear.preference(key: LabelWidthKey.self, value: $0.size.width) })
                .frame(width: labelWidth, alignment: .leading)
                .onTapGesture(count: 2) { if track != nil { reset() } }
                .scrubbable(sensitivity: 1 / step,
                            value: Binding(get: { settings[keyPath: key] }, set: { value in update { $0[keyPath: key] = value } }),
                            range: range)
            if let track {
                CameraRawSlider(value: settings[keyPath: key], range: range, track: track,
                                help: L10n.text("%@. Double-click to reset.", String(describing: title)),
                                onChange: { value in update { $0[keyPath: key] = (value * step).rounded() / step } },
                                onReset: reset)
            } else {
                Slider(value: Binding(get: { logarithmic ? log(settings[keyPath: key]) : settings[keyPath: key] },
                                      set: { value in update { $0[keyPath: key] = ((logarithmic ? exp(value) : value) * step).rounded() / step } }),
                       in: logarithmic ? log(range.lowerBound)...log(range.upperBound) : range)
            }
            TextField(L10n.text(title), value: Binding(get: { settings[keyPath: key] }, set: { value in update { $0[keyPath: key] = value } }),
                      format: .number.precision(.fractionLength(0...decimals)))
                .frame(width: 56).textFieldStyle(.roundedBorder).multilineTextAlignment(.trailing)
                .unitSuffix(unit)
        }
    }
}

/// Gradient Map's two colors, the gradient they make, and Reverse. The colors are swatches like the
/// tool rail's, and open the app's own color picker.
struct GradientMapControls: View {
    @Binding var settings: GradientMapSettings
    /// Opens the color picker on an end: false for Shadows, true for Highlights.
    let pick: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            let ends = settings.ends
            LinearGradient(colors: [color(ends.dark), color(ends.light)], startPoint: .leading, endPoint: .trailing)
                .frame(height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay { RoundedRectangle(cornerRadius: 4, style: .continuous).strokeBorder(.black.opacity(0.35)) }
                .accessibilityHidden(true)
            HStack(spacing: 20) {
                swatch(L10n.text("Shadows"), settings.shadows) { pick(false) }
                swatch(L10n.text("Highlights"), settings.highlights) { pick(true) }
                Spacer()
            }
            Toggle(L10n.text("Reverse"), isOn: $settings.reversed)
        }
    }

    private func color(_ value: AdjustmentColor) -> Color { Color(.sRGB, red: value.red, green: value.green, blue: value.blue) }

    private func swatch(_ title: String, _ value: AdjustmentColor, action: @escaping () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        return HStack(spacing: 8) {
            Button(action: action) {
                shape
                    .fill(color(value))
                    .overlay { shape.inset(by: 1).strokeBorder(.white, lineWidth: 1.5) }
                    .overlay { shape.strokeBorder(.black, lineWidth: 1) }
                    .frame(width: 24, height: 24)
                    .contentShape(shape)
            }
            .buttonStyle(.plain)
            .help(L10n.text("Choose the %@ color", String(describing: title.lowercased())))
            .accessibilityLabel(L10n.text("%@ color", String(describing: title)))
            Text(L10n.text(title))
        }
    }
}

private struct LabelWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
