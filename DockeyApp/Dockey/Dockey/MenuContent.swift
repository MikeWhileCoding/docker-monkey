//
//  MenuContent.swift
//  Dockey
//
//  Created by Mike de Groot on 26/08/2025.
//
import SwiftUI
import CoreKit

struct MenuContent: View {
    @ObservedObject var model: MenuModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if model.projects.isEmpty {
                Text("No projects found")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                
                Row("Reload", systemImage: "arrow.clockwise") {
                    Task { await model.reloadAll() }
                }
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(model.projects, id: \.id) { p in
                            ProjectSection(model: model, project: p)
                                .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.25)))
                                .padding(.horizontal, 6)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Divider().padding(.horizontal, 6)

                Row("Reload", systemImage: "arrow.clockwise") {
                    Task { await model.reloadAll() }
                }
            }

            if model.isRunning || !model.runningLabel.isEmpty {
                Divider().padding(.horizontal, 6)
                if model.isRunning {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(model.runningLabel)
                        Spacer()
                    }
                    .font(.footnote)
                    .padding(.horizontal, 8)
                } else {
                    Text(model.runningLabel)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                }
            }

            Divider().padding(.horizontal, 6)

            Row("Show Log", systemImage: "text.justify.left") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.sendAction(#selector(NSWindow.makeKeyAndOrderFront(_:)), to: nil, from: nil)
            }

            SettingsLink { Label("Settings", systemImage: "gearshape") }
                .labelStyle(RowLabelStyle())    // make Settings look like a row

            Row("Quit Dockey", systemImage: "power", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.vertical, 8)
        .frame(minWidth: 320)
    }
}

private struct ProjectSection: View {
    @ObservedObject var model: MenuModel
    let project: Project

    @State private var openRoot = true
    @State private var openContainers = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.name)
                .font(.headline)
                .padding(.top, 6)
                .padding(.horizontal, 8)

            // Root commands
            DisclosureGroup(isExpanded: $openRoot) {
                let cmds = (model.commandsByProject[project.id ?? -1] ?? []).filter { $0.containerId == nil }
                if cmds.isEmpty {
                    Text("None").foregroundStyle(.secondary).padding(.horizontal, 12).padding(.bottom, 4)
                } else {
                    VStack(spacing: 0) {
                        ForEach(cmds, id: \.id) { cmd in
                            Row(cmd.name, systemImage: "play.circle") {
                                model.run(project: project, command: cmd)
                            }
                        }
                    }
                }
            } label: {
                SectionHeader("Root commands", systemImage: "square.grid.2x2")
            }
            .padding(.horizontal, 6)

            // Containers & their commands
            let containers = model.containersByProject[project.id ?? -1] ?? []
            if !containers.isEmpty {
                DisclosureGroup(isExpanded: $openContainers) {
                    VStack(spacing: 8) {
                        ForEach(containers, id: \.id) { container in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(container.name) [\(container.shell.rawValue)]")
                                    .font(.subheadline).bold()
                                    .padding(.horizontal, 10)

                                let cmds = (model.commandsByProject[project.id ?? -1] ?? [])
                                    .filter { $0.containerId == container.id }

                                if cmds.isEmpty {
                                    Text("None")
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 12)
                                } else {
                                    VStack(spacing: 0) {
                                        ForEach(cmds, id: \.id) { cmd in
                                            Row(cmd.name, systemImage: "play.circle") {
                                                model.run(project: project, command: cmd)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 6)
                } label: {
                    SectionHeader("Containers", systemImage: "shippingbox")
                }
                .padding(.horizontal, 6)
            }
        }
        .padding(.bottom, 8)
    }
}

private struct SectionHeader: View {
    let title: String
    let systemImage: String
    init(_ title: String, systemImage: String) {
        self.title = title; self.systemImage = systemImage
    }
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title).font(.subheadline).bold()
            Spacer()
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
}

/// A **clickable row** with no button chrome.
/// - full-width hit area
/// - plain style
/// - optional destructive role (red text)
private struct Row: View {
    let title: String
    let systemImage: String?
    let role: ButtonRole?
    let action: () -> Void

    @State private var isHovering = false

    init(_ title: String, systemImage: String? = nil, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isHovering ? Color.accentColor.opacity(0.15) : Color.clear)
            .contentShape(Rectangle()) // makes whole row clickable
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

/// Make `SettingsLink` look like our Row
private struct RowLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
            configuration.title
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
