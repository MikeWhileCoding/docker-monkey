//
//  ProjectContainerCLI.swift
//  Dockey
//
//  Created by Mike de Groot on 25/08/2025.
//

import ArgumentParser
import CoreKit

// MARK: - project container
struct ProjectContainerCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "container",
        abstract: "Manage containers inside a project",
        subcommands: [ContainerAdd.self, ContainerList.self, ContainerRemove.self]
    )
}

struct ContainerAdd: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Add a container")

    @Argument(help: "Project name") var project: String
    @Argument(help: "Container name") var name: String
    @Option(name: .shortAndLong, help: "Shell type (zsh, bash, fish)") var shell: String?

    func run() throws {
        let store = ProjectStore()
        guard let p = try store.fetchProject(named: project) else {
            throw ValidationError("Unknown project: \(project)")
        }
        let defaults = DefaultsStore.load()
        let st = ShellType(rawValue: shell ?? defaults.defaultShell.rawValue) ?? defaults.defaultShell
        let id = try store.upsertContainer(projectId: p.id!, name: name, shell: st)
        print("✅ Container '\(name)' added to project '\(project)' with id \(id)")
    }
}

struct ContainerList: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "List containers for a project")

    @Argument(help: "Project name") var project: String

    func run() throws {
        let store = ProjectStore()
        guard let p = try store.fetchProject(named: project) else {
            throw ValidationError("Unknown project: \(project)")
        }
        let containers = try store.containers(for: p.id!)
        if containers.isEmpty {
            print("No containers in project \(project).")
        } else {
            for c in containers {
                print("- \(c.name) [\(c.shell.rawValue)]")
            }
        }
    }
}

struct ContainerRemove: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Remove a container")

    @Argument(help: "Project name") var project: String
    @Argument(help: "Container name") var name: String

    func run() throws {
        let store = ProjectStore()
        guard let p = try store.fetchProject(named: project) else {
            throw ValidationError("Unknown project: \(project)")
        }
        // quick remove by name
        if let c = try store.containers(for: p.id!).first(where: { $0.name == name }) {
            try store.deleteContainer(id: c.id!)
            print("🗑 Removed container '\(name)' from project '\(project)'")
        } else {
            print("❌ Container not found: \(name)")
        }
    }
}
