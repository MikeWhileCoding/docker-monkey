//
//  LogView.swift
//  Dockey
//
//  Created by Mike de Groot on 26/08/2025.
//


import SwiftUI

struct LogView: View {
    @ObservedObject var model: MenuModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Live Log").font(.title3).bold()
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(model.log, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .keyboardShortcut("c", modifiers: [.command])
            }
            .padding(.bottom, 4)

            ScrollViewReader { proxy in
                ScrollView {
                    Text(model.log.isEmpty ? "No output yet." : model.log)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(.vertical, 4)
                        .id("bottom")
                }
                .onChange(of: model.log) { _, _ in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
        .padding(12)
    }
}

struct SettingsView: View {
    @ObservedObject var model: MenuModel

    var body: some View {
        TabView {
            GeneralSettingsView(model: model)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            ProjectsSettingsView(model: model)
                .tabItem {
                    Label("Projects", systemImage: "folder")
                }

            ContainersSettingsView(model: model)
                .tabItem {
                    Label("Containers", systemImage: "shippingbox")
                }

            CommandsSettingsView(model: model)
                .tabItem {
                    Label("Commands", systemImage: "terminal")
                }
        }
        .frame(width: 550, height: 500)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var model: MenuModel
    @State private var autoRefresh = true

    var body: some View {
        Form {
            Toggle("Auto-refresh on launch", isOn: $autoRefresh)
            Button {
                Task { await model.reloadAll() }
            } label: {
                Label("Reload data now", systemImage: "arrow.clockwise")
            }
        }
        .padding()
    }
}
