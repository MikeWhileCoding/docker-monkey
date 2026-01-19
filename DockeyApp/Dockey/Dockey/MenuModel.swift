//
//  MenuModel.swift
//  Dockey
//
//  Created by Mike de Groot on 26/08/2025.
//


import Foundation
import SwiftUI
import CoreKit

@MainActor
final class MenuModel: ObservableObject {
    // Data
    @Published var projects: [Project] = []
    @Published var containersByProject: [Int64: [Container]] = [:]
    @Published var commandsByProject: [Int64: [Command]] = [:]

    // UI state
    @Published var isRunning = false
    @Published var runningLabel = ""
    @Published var log = ""
    @Published var selectedProjectId: Int64?

    private let store = ProjectStore()

    init() {
        Task { await reloadAll() }
    }

    func reloadAll() async {
        do {
            let ps = try store.listProjects()
            projects = ps
            var conts: [Int64 : [Container]] = [:]
            var cmds:  [Int64 : [Command]] = [:]
            for p in ps {
                guard let id = p.id else { continue }
                conts[id] = try store.containers(for: id)
                cmds[id]  = try store.commands(for: id) // all commands (root + container-scoped)
            }
            containersByProject = conts
            commandsByProject = cmds
        } catch {
            runningLabel = "Load failed: \(error)"
        }
    }

    // MARK: Execute

    func run(project: Project, command: Command) {
        guard !isRunning, let pid = project.id else { return }
        isRunning = true
        runningLabel = "Running \(command.name) in \(project.name)…"
        log = ""
        selectedProjectId = pid

        Task.detached { [weak self] in
            guard let self else { return }
            do {
                // Resolve working directory
                let root = project.rootPath
                // Add common paths AND source user's shell config for full environment
                let envSetup = """
                export PATH="/opt/homebrew/bin:/usr/local/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"
                source ~/.zprofile 2>/dev/null
                source ~/.zshrc 2>/dev/null
                """
                let script = "\(envSetup) && cd \(root.shellEscaped) && \(command.script)"
                // Stream output
                for try await line in Shell.stream("/bin/zsh", ["-c", script]) {
                    await self.appendLog(line.text)
                }
                await MainActor.run {
                    self.isRunning = false
                    self.runningLabel = "Done: \(command.name)"
                }
            } catch {
                await self.appendLog("❌ \(error)")
                await MainActor.run {
                    self.isRunning = false
                    self.runningLabel = "Failed: \(command.name)"
                }
            }
        }
    }

    @MainActor
    private func appendLog(_ s: String) {
        log += s + "\n"
    }

    // MARK: - CRUD Operations for Settings

    // Projects
    func addProject(name: String, rootPath: String) async {
        do {
            _ = try store.upsertProject(name: name, rootPath: rootPath)
            await reloadAll()
        } catch {
            runningLabel = "Failed to add project: \(error)"
        }
    }

    func updateProject(_ project: Project, name: String, rootPath: String) async {
        do {
            _ = try store.upsertProject(name: name, rootPath: rootPath)
            // If name changed, delete the old one
            if project.name != name {
                try store.deleteProject(id: project.id!)
            }
            await reloadAll()
        } catch {
            runningLabel = "Failed to update project: \(error)"
        }
    }

    func deleteProject(_ project: Project) async {
        do {
            guard let id = project.id else { return }
            try store.deleteProject(id: id)
            await reloadAll()
        } catch {
            runningLabel = "Failed to delete project: \(error)"
        }
    }

    // Containers
    func addContainer(projectId: Int64, name: String, shell: ShellType) async {
        do {
            _ = try store.upsertContainer(projectId: projectId, name: name, shell: shell)
            await reloadAll()
        } catch {
            runningLabel = "Failed to add container: \(error)"
        }
    }

    func deleteContainer(_ container: Container) async {
        do {
            guard let id = container.id else { return }
            try store.deleteContainer(id: id)
            await reloadAll()
        } catch {
            runningLabel = "Failed to delete container: \(error)"
        }
    }

    // Commands
    func addCommand(projectId: Int64, containerId: Int64?, name: String, script: String) async {
        do {
            _ = try store.upsertCommand(projectId: projectId, containerId: containerId, name: name, script: script)
            await reloadAll()
        } catch {
            runningLabel = "Failed to add command: \(error)"
        }
    }

    func deleteCommand(_ command: Command) async {
        do {
            guard let id = command.id else { return }
            try store.deleteCommand(id: id)
            await reloadAll()
        } catch {
            runningLabel = "Failed to delete command: \(error)"
        }
    }
}

private extension String {
    var shellEscaped: String {
        "'" + self.replacingOccurrences(of: "'", with: "'\"'\"'") + "'"
    }
}
