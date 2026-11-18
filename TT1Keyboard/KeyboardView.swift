import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// KeyboardView.swift
// TT1 Keyboard — iOS SwiftUI UI
// Mirrors KeyboardScreen.kt (Compose) exactly:
//   • FloatingAutoControl: 18-mode auto-generator floating bar (Start/Stop/Close)
//   • NumericLayout: mode selector, digit grid (1-9 + 0), slide input, comma toggle
//   • QwertyLayout: 4 rows (letters, shift, bottom bar)
//   • Layout toggle button (🔁 → Abc → 123)
// ─────────────────────────────────────────────────────────────────────────────

// ── Design constants ──────────────────────────────────────────────────────────
private let keyHeight: CGFloat       = 54
private let keySpacing: CGFloat      = 4
private let keyCorner: CGFloat       = 6
private let keyTextSize: CGFloat     = 17
private let bgScreen   = Color(hex: 0x111111)
private let bgKey      = Color(hex: 0x333333)
private let bgDim      = Color(hex: 0x555555)
private let bgMode4    = Color(hex: 0x2196F3)
private let bgMode5    = Color(hex: 0x4CAF50)
private let bgMode6    = Color(hex: 0xFF9800)
private let bgMode18   = Color(hex: 0x9C27B0)

// ── Adjacency map (identical to Kotlin ADJACENCY) ────────────────────────────
// Grid:  1 2 3
//        4 5 6
//        7 8 9
//       🔁 0 ,
private let ADJACENCY: [Character: Set<Character>] = [
    "1": ["2", "4"],
    "2": ["1", "3", "5"],
    "3": ["2", "6"],
    "4": ["1", "5", "7"],
    "5": ["2", "4", "6", "8"],
    "6": ["3", "5", "9"],
    "7": ["4", "8"],
    "8": ["7", "9", "5", "0"],
    "9": ["6", "8"],
    "0": ["8"],
]

private func isAdjacent(_ a: Character, _ b: Character) -> Bool {
    ADJACENCY[a]?.contains(b) == true
}

// ── Color hex init helper ─────────────────────────────────────────────────────
extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >>  8) & 0xFF) / 255
        let b = Double( hex        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// KeyboardView — root
// ─────────────────────────────────────────────────────────────────────────────

struct KeyboardView: View {
    @ObservedObject var state: KeyboardState

    // Callbacks wired to KeyboardViewController
    let onDigit:           (Character) -> Void
    let onRepeatLastDigit: () -> Void
    let onCommitText:      (String) -> Void
    let onBackspace:       () -> Void
    let onSend:            () -> Void
    let onSetMode:         (Int) -> Void
    let onCommaToggle:     () -> Void
    let onSwitchToNumeric: () -> Void
    let onSwitchToQwerty:  () -> Void
    let onStartAuto:       () -> Void
    let onStopAuto:        () -> Void

    var body: some View {
        VStack(spacing: keySpacing) {
            if state.isNumericLayout {
                NumericLayout(
                    state: state,
                    onDigit: onDigit,
                    onRepeatLastDigit: onRepeatLastDigit,
                    onSetMode: onSetMode,
                    onCommaToggle: onCommaToggle,
                    onToggleLayout: {
                        if state.toggleLabel == "🔁" || state.toggleLabel == "123" {
                            onSwitchToQwerty()
                        } else {
                            onSwitchToNumeric()
                        }
                    },
                    onStartAuto: onStartAuto,
                    onStopAuto: onStopAuto
                )
            } else {
                QwertyLayout(
                    onCommitText: onCommitText,
                    onBackspace: onBackspace,
                    onSend: onSend,
                    onSwitchToNumeric: onSwitchToNumeric
                )
            }
        }
        .padding(6)
        .background(bgScreen)
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// FloatingAutoControl — 18-Mode Auto Last Digit Generator
// ─────────────────────────────────────────────────────────────────────────────

private struct FloatingAutoControl: View {
    @ObservedObject var state: KeyboardState
    let onStart: () -> Void
    let onStop: () -> Void

    var body: some View {
        if !state.isControlOpen {
            // CLOSED STATE: small floating pill at top (does not interfere with typing)
            Button(action: { state.isControlOpen = true }) {
                HStack(spacing: 6) {
                    Text("18")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(state.isAutoActive ? Color(hex: 0x4CAF50) : Color(hex: 0x9E9E9E))
                        .cornerRadius(4)

                    Text(state.isAutoActive ? "Auto: \(state.autoStatus) ▾" : "Auto Gen ▾")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(state.isAutoActive ? Color(hex: 0x4CAF50) : Color(hex: 0xCCCCCC))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color(hex: 0x222222))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 1)
        } else {
            // OPENED STATE: shows status, Start, Stop, and Close buttons
            HStack(spacing: 8) {
                // Status indicator
                VStack(alignment: .leading, spacing: 2) {
                    Text("18-Auto Generator")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: 0x9C27B0))
                    Text(state.autoStatus)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(statusColor(state.autoStatus))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Start button
                Button(action: onStart) {
                    Text("Start")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: 0x2E7D32))
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())

                // Stop button
                Button(action: onStop) {
                    Text("Stop")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(hex: 0xC62828))
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())

                // Close button (hide control)
                Button(action: { state.isControlOpen = false }) {
                    Text("✕")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(hex: 0x444444))
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(hex: 0x1E1E1E))
            .cornerRadius(8)
        }
    }

    private func statusColor(_ status: String) -> Color {
        if status.hasPrefix("Sending") || status.hasPrefix("Done") {
            return Color(hex: 0x4CAF50)
        } else if status.hasPrefix("Armed") {
            return Color(hex: 0xFF9800)
        } else if status == "Stopped" || status == "Error" {
            return Color(hex: 0xE57373)
        } else {
            return .white
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// NumericLayout
// ─────────────────────────────────────────────────────────────────────────────

private struct NumericLayout: View {
    @ObservedObject var state: KeyboardState
    let onDigit:           (Character) -> Void
    let onRepeatLastDigit: () -> Void
    let onSetMode:         (Int) -> Void
    let onCommaToggle:     () -> Void
    let onToggleLayout:    () -> Void
    let onStartAuto:       () -> Void
    let onStopAuto:        () -> Void

    // Slide-input state
    @State private var keyFrames: [Character: CGRect] = [:]
    @State private var slideLastKey: Character? = nil
    @State private var slideVisited: Set<Character> = []

    private let digitRows: [[Character]] = [
        ["1","2","3"],
        ["4","5","6"],
        ["7","8","9"],
    ]

    var body: some View {
        VStack(spacing: keySpacing) {
            // ── Floating Auto-Generator Control (only in Mode 18) ─────────
            if state.mode == 18 {
                FloatingAutoControl(
                    state: state,
                    onStart: onStartAuto,
                    onStop: onStopAuto
                )
            }

            // ── Mode selector row ─────────────────────────────────────────
            HStack(spacing: keySpacing) {
                ForEach([(4,"4"),(5,"5"),(6,"6"),(18,"18")], id: \.0) { m, label in
                    KeyButton(
                        text: label,
                        bg: modeColor(m, selected: state.mode == m)
                    ) { onSetMode(m) }
                }
            }
            .frame(height: keyHeight)

            // ── Digit grid (with slide-input gesture overlay) ─────────────
            VStack(spacing: keySpacing) {
                ForEach(digitRows, id: \.self) { row in
                    HStack(spacing: keySpacing) {
                        ForEach(row, id: \.self) { digit in
                            DigitKeyCell(digit: digit) { rect in
                                keyFrames[digit] = rect
                            }
                        }
                    }
                    .frame(height: keyHeight)
                }

                // Bottom row: toggle | 0 | comma
                HStack(spacing: keySpacing) {
                    KeyButton(text: state.toggleLabel, bg: bgKey, action: onToggleLayout)

                    DigitKeyCell(digit: "0") { rect in
                        keyFrames["0"] = rect
                    }

                    KeyButton(
                        text: ",",
                        bg: state.isCommaActive ? bgMode4 : bgKey,
                        action: onCommaToggle
                    )
                }
                .frame(height: keyHeight)
            }
            // ── Slide-input gesture on the entire digit area ───────────────
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        let pt = value.location

                        // Hit-test: find which digit key is under the touch
                        let hit = keyFrames.first { _, rect in
                            rect.contains(pt)
                        }?.key

                        if value.translation == .zero {
                            // Finger just touched down
                            if let h = hit {
                                onDigit(h)
                                slideLastKey = h
                                slideVisited = [h]
                            }
                        } else {
                            // Finger sliding
                            if let h = hit,
                               let last = slideLastKey,
                               !slideVisited.contains(h),
                               isAdjacent(last, h) {
                                onDigit(h)
                                slideVisited.insert(h)
                                slideLastKey = h
                            }
                        }
                    }
                    .onEnded { _ in
                        slideLastKey = nil
                        slideVisited = []
                    }
            )
        }
    }

    private func modeColor(_ m: Int, selected: Bool) -> Color {
        guard selected else { return bgDim }
        switch m {
        case 4:  return bgMode4
        case 5:  return bgMode5
        case 6:  return bgMode6
        default: return bgMode18
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// DigitKeyCell — static display only; gesture handled by parent
// ─────────────────────────────────────────────────────────────────────────────

private struct DigitKeyCell: View {
    let digit: Character
    let onFrameReady: (CGRect) -> Void

    var body: some View {
        Text(String(digit))
            .font(.system(size: keyTextSize, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(bgKey)
            .cornerRadius(keyCorner)
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        let frame = geo.frame(in: .global)
                        onFrameReady(frame)
                    }
                    .onChange(of: geo.frame(in: .global)) { newFrame in
                        onFrameReady(newFrame)
                    }
                }
            )
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// QwertyLayout — 4 rows matching Android layout exactly
// Row 1: q w e r t y u i o p
// Row 2: a s d f g h j k l
// Row 3: ⇧ z x c v b n m ⌫
// Row 4: ?123 😊 EN•SO . ↵
// ─────────────────────────────────────────────────────────────────────────────

private struct QwertyLayout: View {
    let onCommitText:      (String) -> Void
    let onBackspace:       () -> Void
    let onSend:            () -> Void
    let onSwitchToNumeric: () -> Void

    @State private var isShifted: Bool = false

    private let row1 = Array("qwertyuiop").map { String($0) }
    private let row2 = Array("asdfghjkl").map { String($0) }
    private let row3 = Array("zxcvbnm").map { String($0) }

    var body: some View {
        VStack(spacing: keySpacing) {
            // Row 1
            HStack(spacing: keySpacing) {
                ForEach(row1, id: \.self) { l in
                    let t = isShifted ? l.uppercased() : l
                    KeyButton(text: t, bg: bgKey) { onCommitText(t) }
                }
            }
            .frame(height: keyHeight)

            // Row 2 (slightly inset on both sides like Android)
            HStack(spacing: keySpacing) {
                ForEach(row2, id: \.self) { l in
                    let t = isShifted ? l.uppercased() : l
                    KeyButton(text: t, bg: bgKey) { onCommitText(t) }
                }
            }
            .frame(height: keyHeight)
            .padding(.horizontal, 10)

            // Row 3: Shift + letters + Backspace
            HStack(spacing: keySpacing) {
                KeyButton(
                    text: isShifted ? "⇪" : "⇧",
                    bg: isShifted ? bgMode4 : bgDim
                ) { isShifted.toggle() }
                .frame(width: 44)

                ForEach(row3, id: \.self) { l in
                    let t = isShifted ? l.uppercased() : l
                    KeyButton(text: t, bg: bgKey) { onCommitText(t) }
                }

                KeyButton(text: "⌫", bg: bgDim, action: onBackspace)
                    .frame(width: 44)
            }
            .frame(height: keyHeight)

            // Row 4: ?123 | 😊 | Spacebar | . | Enter
            HStack(spacing: keySpacing) {
                KeyButton(text: "?123", bg: bgDim, action: onSwitchToNumeric)
                    .frame(width: 52)

                KeyButton(text: "😊", bg: bgDim) { onCommitText("😊") }
                    .frame(width: 40)

                KeyButton(text: "EN • SO", bg: bgKey) { onCommitText(" ") }
                    .frame(maxWidth: .infinity)

                KeyButton(text: ".", bg: bgKey) { onCommitText(".") }
                    .frame(width: 36)

                KeyButton(text: "↵", bg: bgMode4, action: onSend)
                    .frame(width: 52)
            }
            .frame(height: keyHeight)
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// KeyButton — generic tappable key (instant down-action, no delay)
// ─────────────────────────────────────────────────────────────────────────────

private struct KeyButton: View {
    let text: String
    let bg: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Text(text)
            .font(.system(size: text == "18" ? 15 : keyTextSize, weight: .medium))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isPressed ? bg.opacity(0.6) : bg)
            .cornerRadius(keyCorner)
            // Instant touch-down action (no tap delay)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            action()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}
