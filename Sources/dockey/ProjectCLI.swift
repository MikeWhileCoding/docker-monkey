//
//  ProjectCLI.swift
//  Dockey
//
//  Created by Mike de Groot on 25/08/2025.
//

import ArgumentParser
import CoreKit

// MARK: - Top-level "project" command
struct ProjectCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "project",
        abstract: "Manage projects, containers, and commands",
        subcommands: [ProjectAdd.self, ProjectList.self, ProjectRemove.self,
                      ProjectContainerCLI.self, ProjectCommandCLI.self]
    )
}

// MARK: Project operations
struct ProjectAdd: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a new project"
    )

    @Argument(help: "Project name") var name: String
    @Option(name: .shortAndLong, help: "Root directory") var root: String?

    func run() throws {
        let store = ProjectStore()
        let defaults = DefaultsStore.load()
        let id = try store.upsertProject(name: name, rootPath: root ?? defaults.defaultProjectRoot)
        print("✅ Project '\(name)' created with id \(id)")
    }
}

struct ProjectList: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List projects"
    )

    func run() throws {
        let store = ProjectStore()
        let projects = try store.listProjects()
        if projects.isEmpty {
            print("No projects found.")
        } else {
            for p in projects {
                print("- \(p.name) @ \(p.rootPath)")
            }
        }
    }
}

struct ProjectRemove: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "rm",
        abstract: "Remove a project"
    )

    @Argument(help: "Project name") var name: String

    func run() throws {
        let store = ProjectStore()
        if let p = try store.fetchProject(named: name) {
            try store.deleteProject(id: p.id!)
            print("🗑 Removed project '\(name)'")
        } else {
            print("❌ Project not found: \(name)")
        }
    }
}
