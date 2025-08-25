//
//  ProjectCommandCLI.swift
//  Dockey
//
//  Created by Mike de Groot on 25/08/2025.
//

import ArgumentParser
import CoreKit

// MARK: - project command
struct ProjectCommandCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "command",
        abstract: "Manage commands inside a project",
        subcommands: [CommandAdd.self, CommandList.self, CommandRemove.self, CommandRun.self]
    )
}

struct CommandAdd: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Add a command")

    @Argument(help: "Project name") var project: String
    @Argument(help: "Command name") var name: String
    @Option(name: .shortAndLong, help: "Script to run") var script: String
    @Option(name: .shortAndLong, help: "Container name (optional)") var container: String?

    func run() throws {
        let store = ProjectStore()
        guard let p = try store.fetchProject(named: project) else {
            throw ValidationError("Unknown project: \(project)")
        }
        var containerId: Int64? = nil
        if let cname = container {
            if let c = try store.containers(for: p.id!).first(where: { $0.name == cname }) {
                containerId = c.id
            } else {
                throw ValidationError("Unknown container: \(cname)")
            }
        }
        let id = try store.upsertCommand(projectId: p.id!, containerId: containerId, name: name, script: script)
        print("✅ Command '\(name)' added with id \(id)")
    }
}

struct CommandList: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "List commands in a project")

    @Argument(help: "Project name") var project: String

    func run() throws {
        let store = ProjectStore()
        guard let p = try store.fetchProject(named: project) else {
            throw ValidationError("Unknown project: \(project)")
        }
        let cmds = try store.commands(for: p.id!)
        if cmds.isEmpty {
            print("No commands in project \(project).")
        } else {
            for c in cmds {
                let scope = c.containerId != nil ? "(container \(c.containerId!))" : "(root)"
                print("- \(c.name) \(scope): \(c.script)")
            }
        }
    }
}

struct CommandRemove: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Remove a command")

    @Argument(help: "Project name") var project: String
    @Argument(help: "Command name") var name: String

    func run() throws {
        let store = ProjectStore()
        guard let p = try store.fetchProject(named: project) else {
            throw ValidationError("Unknown project: \(project)")
        }
        if let c = try store.commands(for: p.id!).first(where: { $0.name == name }) {
            try store.deleteCommand(id: c.id!)
            print("🗑 Removed command '\(name)'")
        } else {
            print("❌ Command not found: \(name)")
        }
    }
}

struct CommandRun: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Run a command")

    @Argument(help: "Project name") var project: String
    @Argument(help: "Command name") var name: String

    func run() throws {
        let store = ProjectStore()
        guard let graph = try store.loadProjectGraph(named: project) else {
            throw ValidationError("Unknown project: \(project)")
        }
        guard let cmd = graph.commands.first(where: { $0.name == name }) else {
            throw ValidationError("Unknown command: \(name)")
        }
        let root = graph.project.rootPath
        let base = "cd '\(root)' && \(cmd.script)"
        let (_, out, err) = try Shell.run("/bin/zsh", ["-lc", base])
        print(out + err)
    }
}
