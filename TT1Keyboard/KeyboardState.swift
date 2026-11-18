import SwiftUI
import Combine

// ─────────────────────────────────────────────────────────────────────────────
// KeyboardState.swift
// Observable state shared between KeyboardViewController and KeyboardView
// ─────────────────────────────────────────────────────────────────────────────

final class KeyboardState: ObservableObject {
    @Published var mode: Int = 4
    @Published var isCommaActive: Bool = false
    @Published var isNumericLayout: Bool = true
    @Published var toggleLabel: String = "🔁"
    
    // ── 18-Mode Auto Last Digit Generator state ──────────────────────────────
    @Published var autoStatus: String = "Idle"
    @Published var isAutoActive: Bool = false
    @Published var isControlOpen: Bool = false
}
