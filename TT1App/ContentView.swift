import SwiftUI

// ─────────────────────────────────────────────────────────────────────────────
// ContentView.swift — Container app (required by Apple to host keyboard extension)
// This is just a simple setup guide screen; the actual keyboard is the extension.
// ─────────────────────────────────────────────────────────────────────────────

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "keyboard")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                Text("TT1 Keyboard")
                    .font(.largeTitle.bold())

                VStack(alignment: .leading, spacing: 16) {
                    Text("To enable TT1 Keyboard:")
                        .font(.headline)

                    Label("Open Settings", systemImage: "1.circle.fill")
                    Label("Tap General → Keyboard → Keyboards", systemImage: "2.circle.fill")
                    Label("Tap Add New Keyboard...", systemImage: "3.circle.fill")
                    Label("Select TT1 Keyboard", systemImage: "4.circle.fill")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                Button("Open Keyboard Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}
