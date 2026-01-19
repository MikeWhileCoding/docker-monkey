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
    @StateObject private var model = MenuModel()

    var body: some Scene {
        MenuBarExtra("Dockey", systemImage: "hammer") {
            MenuContent(model: model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }

        Window("Dockey Log", id: "log") {
            LogView(model: model)
                .frame(minWidth: 640, minHeight: 380)
        }
        .defaultPosition(.center)
        .defaultSize(width: 700, height: 420)
    }
}
