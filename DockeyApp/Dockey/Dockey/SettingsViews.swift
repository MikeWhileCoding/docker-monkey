//
//  SettingsViews.swift
//  Dockey
//
//  Created by Mike de Groot on 19/01/2026.
//

import SwiftUI
import CoreKit

// MARK: - Projects Tab

struct ProjectsSettingsView: View {
    @ObservedObject var model: MenuModel
    @State private var showingAddSheet = false
    @State private var editingProject: Project?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Projects")
                    .font(.headline)
                Spacer()
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Project", systemImage: "plus")
                }
            }

            if model.projects.isEmpty {
                Text("No projects yet. Add one to get started.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                List {
                    ForEach(model.projects, id: \.id) { project in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(project.name)
                                    .font(.body.bold())
                                Text(project.rootPath)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                editingProject = project
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.borderless)

                            Button(role: .destructive) {
                                Task { await model.deleteProject(project) }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ProjectFormSheet(model: model, project: nil)
        }
        .sheet(item: $editingProject) { project in
            ProjectFormSheet(model: model, project: project)
        }
    }
}

struct ProjectFormSheet: View {
    @ObservedObject var model: MenuModel
    let project: Project?

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var rootPath = ""

    var isEditing: Bool { project != nil }

    var body: some View {
        VStack(spacing: 16) {
            Text(isEditing ? "Edit Project" : "Add Project")
                .font(.headline)

            Form {
                TextField("Name", text: $name)
                TextField("Root Path", text: $rootPath)

                HStack {
                    Button("Choose...") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            rootPath = url.path
                        }
                    }
                }
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "Save" : "Add") {
                    Task {
                        if let project = project {
                            await model.updateProject(project, name: name, rootPath: rootPath)
                        } else {
                            await model.addProject(name: name, rootPath: rootPath)
                        }
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || rootPath.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            if let project = project {
                name = project.name
                rootPath = project.rootPath
            }
        }
    }
}

// MARK: - Containers Tab

struct ContainersSettingsView: View {
    @ObservedObject var model: MenuModel
    @State private var selectedProjectId: Int64?
    @State private var showingAddSheet = false

    var containers: [Container] {
        guard let id = selectedProjectId else { return [] }
        return model.containersByProject[id] ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Containers")
                    .font(.headline)
                Spacer()

                Picker("Project", selection: $selectedProjectId) {
                    Text("Select project...").tag(nil as Int64?)
                    ForEach(model.projects, id: \.id) { project in
                        Text(project.name).tag(project.id as Int64?)
                    }
                }
                .frame(width: 200)

                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Container", systemImage: "plus")
                }
                .disabled(selectedProjectId == nil)
            }

            if selectedProjectId == nil {
                Text("Select a project to manage containers.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if containers.isEmpty {
                Text("No containers in this project.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                List {
                    ForEach(containers, id: \.id) { container in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(container.name)
                                    .font(.body.bold())
                                Text("Shell: \(container.shell.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()

                            Button(role: .destructive) {
                                Task { await model.deleteContainer(container) }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ContainerFormSheet(model: model, projectId: selectedProjectId!)
        }
    }
}

struct ContainerFormSheet: View {
    @ObservedObject var model: MenuModel
    let projectId: Int64

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var shell: ShellType = .bash

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Container")
                .font(.headline)

            Form {
                TextField("Name", text: $name)
                Picker("Shell", selection: $shell) {
                    ForEach(ShellType.allCases, id: \.self) { shellType in
                        Text(shellType.rawValue).tag(shellType)
                    }
                }
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    Task {
                        await model.addContainer(projectId: projectId, name: name, shell: shell)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 350)
    }
}

// MARK: - Commands Tab

struct CommandsSettingsView: View {
    @ObservedObject var model: MenuModel
    @State private var selectedProjectId: Int64?
    @State private var showingAddSheet = false
    @State private var testOutput = ""
    @State private var isRunningTest = false
    @State private var runningCommandName = ""

    var commands: [Command] {
        guard let id = selectedProjectId else { return [] }
        return model.commandsByProject[id] ?? []
    }

    var containers: [Container] {
        guard let id = selectedProjectId else { return [] }
        return model.containersByProject[id] ?? []
    }

    var selectedProject: Project? {
        model.projects.first { $0.id == selectedProjectId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Commands")
                    .font(.headline)
                Spacer()

                Picker("Project", selection: $selectedProjectId) {
                    Text("Select project...").tag(nil as Int64?)
                    ForEach(model.projects, id: \.id) { project in
                        Text(project.name).tag(project.id as Int64?)
                    }
                }
                .frame(width: 200)

                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Command", systemImage: "plus")
                }
                .disabled(selectedProjectId == nil)
            }

            if selectedProjectId == nil {
                Text("Select a project to manage commands.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else if commands.isEmpty {
                Text("No commands in this project.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                List {
                    ForEach(commands, id: \.id) { command in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(command.name)
                                    .font(.body.bold())
                                Text(command.script)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                if let cid = command.containerId,
                                   let container = containers.first(where: { $0.id == cid }) {
                                    Text("Container: \(container.name)")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            Spacer()

                            // Test button
                            Button {
                                runTest(command: command)
                            } label: {
                                Label("Test", systemImage: "play.fill")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .disabled(isRunningTest)

                            Button(role: .destructive) {
                                Task { await model.deleteCommand(command) }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset)
                .frame(maxHeight: 150)
            }

            // Console output area
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Console Output")
                        .font(.subheadline.bold())

                    if isRunningTest {
                        ProgressView()
                            .controlSize(.small)
                        Text("Running \(runningCommandName)...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        testOutput = ""
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .disabled(testOutput.isEmpty)
                }

                ScrollView {
                    Text(testOutput.isEmpty ? "Run a command to see output here." : testOutput)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .foregroundStyle(testOutput.isEmpty ? .secondary : .primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(6)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            CommandFormSheet(model: model, projectId: selectedProjectId!, containers: containers)
        }
    }

    private func runTest(command: Command) {
        guard let project = selectedProject else { return }
        isRunningTest = true
        runningCommandName = command.name
        testOutput = "▶ Running '\(command.name)'...\n\n"

        Task {
            let root = project.rootPath
            // Add common paths AND source user's shell config for full environment
            let envSetup = """
            export PATH="/opt/homebrew/bin:/usr/local/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"
            source ~/.zprofile 2>/dev/null
            source ~/.zshrc 2>/dev/null
            """
            let script = "\(envSetup) && cd '\(root)' && \(command.script)"

            do {
                let (exitCode, stdout, stderr) = try Shell.run("/bin/zsh", ["-c", script])
                let output = stdout + stderr

                if exitCode == 0 {
                    testOutput = "✅ Completed '\(command.name)'\n\n\(output)"
                } else {
                    testOutput = "❌ Failed '\(command.name)' (exit code: \(exitCode))\n\n\(output)"
                }
            } catch {
                testOutput = "❌ Error: \(error)"
            }

            isRunningTest = false
            runningCommandName = ""
        }
    }
}

struct CommandFormSheet: View {
    @ObservedObject var model: MenuModel
    let projectId: Int64
    let containers: [Container]

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var script = ""
    @State private var containerId: Int64?

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Command")
                .font(.headline)

            Form {
                TextField("Name", text: $name)
                TextField("Script", text: $script)

                Picker("Container (optional)", selection: $containerId) {
                    Text("Root (no container)").tag(nil as Int64?)
                    ForEach(containers, id: \.id) { container in
                        Text(container.name).tag(container.id as Int64?)
                    }
                }
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") {
                    Task {
                        await model.addCommand(projectId: projectId, containerId: containerId, name: name, script: script)
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || script.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }
}
