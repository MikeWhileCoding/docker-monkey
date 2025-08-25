//
//  DockeyApp.swift
//  Dockey
//
//  Created by Mike de Groot on 25/08/2025.
//
import SwiftUI
import CoreKit

@main
struct DockeyApp: App {
    @State private var latest = "Ready"

    var body: some Scene {
        MenuBarExtra("Dockey", systemImage: "hammer") {
            Button {
                Task {
                    do {
                        let (_, out, _) = try Shell.run("/bin/echo", ["Build triggered"])
                        latest = out.trimmingCharacters(in: .whitespacesAndNewlines)
                    } catch {
                        latest = "Error: \\(error)"
                    }
                }
            } label: { Label("Build", systemImage: "wrench.and.screwdriver") }

            Divider()
            Text(latest).font(.footnote).foregroundStyle(.secondary)
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
        .menuBarExtraStyle(.window)
    }
}
