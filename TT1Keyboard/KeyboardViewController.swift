import UIKit
import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// KeyboardViewController.swift
// TT1 Keyboard — iOS  (mirrors TT1KeyboardService.kt on Android)
// ─────────────────────────────────────────────────────────────────────────────

class KeyboardViewController: UIInputViewController {

    // ── Constants ────────────────────────────────────────────────────────────
    private static let SEP_DOT   = "."
    private static let SEP_COMMA = ","

    // ── Keyboard state (mirrors TT1KeyboardService.kt) ───────────────────────
    private var mode: Int = 4
    private var digitCount: Int = 0
    private var useCommaSeparator: Bool = false
    private var lastDigit: Character? = nil
    private var enteredDigits: String = ""
    private var autoGenTask: Task<Void, Never>? = nil

    // ── Observable state passed into SwiftUI view ─────────────────────────────
    private let state = KeyboardState()

    // ── View lifecycle ────────────────────────────────────────────────────────

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoGenerate()
    }

    private func setupKeyboardView() {
        let keyboardView = KeyboardView(
            state: state,
            onDigit:           { [weak self] ch in self?.handleDigit(ch) },
            onRepeatLastDigit: { [weak self] in  self?.handleRepeatLastDigit() },
            onCommitText:      { [weak self] s  in self?.textDocumentProxy.insertText(s) },
            onBackspace:       { [weak self] in  self?.handleBackspace() },
            onSend:            { [weak self] in  self?.fireZeroLatencySend() },
            onSetMode:         { [weak self] m  in self?.setMode(m) },
            onCommaToggle:     { [weak self] in  self?.toggleCommaSeparator() },
            onSwitchToNumeric: { [weak self] in  self?.switchToNumeric() },
            onSwitchToQwerty:  { [weak self] in  self?.switchToQwerty() },
            onStartAuto:       { [weak self] in  self?.startAutoGenerateAndSend() },
            onStopAuto:        { [weak self] in  self?.stopAutoGenerate() }
        )

        let host = UIHostingController(rootView: keyboardView)
        addChild(host)
        view.addSubview(host.view)
        host.didMove(toParent: self)

        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // ── 0ms Auto-Send (mirrors fireZeroLatencySend in Kotlin) ─────────────────
    private func fireZeroLatencySend() {
        // insertText("\n") triggers the return action for the focused field —
        // UIKit routes it to the correct action (Send, Go, Search, Done, etc.)
        // with zero additional dispatch delay.
        textDocumentProxy.insertText("\n")
    }

    // ── Auto Last Digit Generator & Sender (18-mode) ─────────────────────────
    private func startAutoGenerateAndSend() {
        guard mode == 18 else { return }
        state.isAutoActive = true
        if enteredDigits.count == 17 {
            executeAutoSendSequence(prefixDigits: enteredDigits)
        } else {
            state.autoStatus = "Armed (\(enteredDigits.count)/17)"
        }
    }

    private func stopAutoGenerate() {
        autoGenTask?.cancel()
        autoGenTask = nil
        state.isAutoActive = false
        state.autoStatus = "Stopped"
    }

    private func clearInputField() {
        var maxCycles = 50
        while let before = textDocumentProxy.documentContextBeforeInput, !before.isEmpty && maxCycles > 0 {
            for _ in 0..<before.count {
                textDocumentProxy.deleteBackward()
            }
            maxCycles -= 1
        }
    }

    private func executeAutoSendSequence(prefixDigits: String) {
        guard prefixDigits.count == 17 else { return }
        autoGenTask?.cancel()

        autoGenTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.state.autoStatus = "Starting..."

            let sep = self.useCommaSeparator
                ? KeyboardViewController.SEP_COMMA
                : KeyboardViewController.SEP_DOT

            let p1Start = prefixDigits.startIndex
            let p1End   = prefixDigits.index(p1Start, offsetBy: 6)
            let p2End   = prefixDigits.index(p1End, offsetBy: 6)
            let p3End   = prefixDigits.index(p2End, offsetBy: 5)

            let p1 = String(prefixDigits[p1Start..<p1End])
            let p2 = String(prefixDigits[p1End..<p2End])
            let p3 = String(prefixDigits[p2End..<p3End])

            let formattedPrefix = "\(p1)\(sep)\(p2)\(sep)\(p3)"

            for digit in 1...9 {
                if Task.isCancelled { break }
                self.state.autoStatus = "Sending (\(digit)/9)..."

                let fullNumber = "\(formattedPrefix)\(digit)"

                // 1. Clear any current text in input field
                self.clearInputField()

                // 2. Insert the complete 18-digit formatted number
                self.textDocumentProxy.insertText(fullNumber)

                // Settle delay for target app's text watcher to enable Send button
                try? await Task.sleep(nanoseconds: 120_000_000) // 120ms
                if Task.isCancelled { break }

                // 3. Perform actual Send button action
                self.fireZeroLatencySend()

                // 4. Wait until the message is submitted successfully by target app
                var waited: UInt64 = 0
                let maxWait: UInt64 = 2_500_000_000 // 2.5s
                let pollInterval: UInt64 = 50_000_000 // 50ms

                while waited < maxWait {
                    try? await Task.sleep(nanoseconds: pollInterval)
                    waited += pollInterval
                    if Task.isCancelled { break }

                    let textNow = self.textDocumentProxy.documentContextBeforeInput ?? ""
                    if textNow.isEmpty {
                        break // Field cleared and message submitted
                    }
                }

                // Buffer delay after submission before preparing next number (avoids spam rate-limit)
                try? await Task.sleep(nanoseconds: 400_000_000) // 400ms
            }

            if !Task.isCancelled {
                self.state.autoStatus = "Done (9/9 sent)"
                self.digitCount = 0
                self.enteredDigits = ""
                self.state.isAutoActive = false
            } else {
                self.state.autoStatus = "Stopped"
            }
        }
    }

    // ── Digit handling (mirrors handleDigit in Kotlin) ────────────────────────
    private func handleDigit(_ d: Character) {
        lastDigit = d
        textDocumentProxy.insertText(String(d))
        digitCount += 1

        // Mode 18: insert separator every 6 digits (not at position 18)
        if mode == 18 {
            enteredDigits.append(d)
            if digitCount % 6 == 0 && digitCount != 18 {
                let sep = useCommaSeparator
                    ? KeyboardViewController.SEP_COMMA
                    : KeyboardViewController.SEP_DOT
                textDocumentProxy.insertText(sep)
            }
            if state.isAutoActive {
                state.autoStatus = "Armed (\(enteredDigits.count)/17)"
            }
        }

        let is18AutoTrigger = (mode == 18 && state.isAutoActive && enteredDigits.count == 17)
        let shouldSend = (digitCount == mode && !is18AutoTrigger)

        if shouldSend {
            digitCount = 0
            enteredDigits = ""
            lastDigit = nil
        }

        if is18AutoTrigger {
            executeAutoSendSequence(prefixDigits: enteredDigits)
        } else if shouldSend {
            fireZeroLatencySend()
        }
    }

    private func handleRepeatLastDigit() {
        guard let d = lastDigit else { return }
        handleDigit(d)
    }

    private func handleBackspace() {
        if mode == 18 {
            if !enteredDigits.isEmpty {
                enteredDigits.removeLast()
            }
            if digitCount > 0 {
                digitCount -= 1
                if state.isAutoActive {
                    state.autoStatus = "Armed (\(enteredDigits.count)/17)"
                }
            }
            if let before = textDocumentProxy.documentContextBeforeInput,
               before.hasSuffix(KeyboardViewController.SEP_DOT) || before.hasSuffix(KeyboardViewController.SEP_COMMA) {
                textDocumentProxy.deleteBackward()
            }
        }
        textDocumentProxy.deleteBackward()
    }

    // ── Mode / layout state changes ────────────────────────────────────────────
    private func setMode(_ m: Int) {
        mode = m
        digitCount = 0
        enteredDigits = ""
        lastDigit = nil
        stopAutoGenerate()
        state.mode = m
    }

    private func toggleCommaSeparator() {
        guard mode == 18 else { return }
        useCommaSeparator.toggle()
        state.isCommaActive = useCommaSeparator
    }

    private func switchToNumeric() {
        state.isNumericLayout = true
        state.toggleLabel = "123"
    }

    private func switchToQwerty() {
        state.isNumericLayout = false
        state.toggleLabel = "Abc"
    }
}
