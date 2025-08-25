//
//  ProjectStore.swift
//  Dockey
//
//  Created by Mike de Groot on 25/08/2025.
//

import Foundation
import GRDB

public struct ProjectWithChildren: Equatable {
    public let project: Project
    public let containers: [Container]
    public let commands: [Command]
}

public final class ProjectStore {
    private let db: DatabaseQueue

    public init(dbQueue: DatabaseQueue = DatabaseProvider.shared.dbQueue) {
        self.db = dbQueue
    }

    // MARK: Projects
    @discardableResult
    public func upsertProject(name: String, rootPath: String) throws -> Int64 {
        try db.write { db in
            var p = Project(id: nil, name: name, rootPath: rootPath, createdAt: Date(), updatedAt: Date())
            try p.save(db)
            return p.id!
        }
    }
    
    public func deleteProject(id: Int64) throws {
        try db.write { db in
            _ = try Project.deleteOne(db, key: id)
        }
    }

    public func fetchProject(named name: String) throws -> Project? {
        try db.read { db in
            try Project.filter(Column("name") == name).fetchOne(db)
        }
    }

    public func listProjects() throws -> [Project] {
        try db.read { db in try Project.order(Column("name")).fetchAll(db) }
    }

    // MARK: Containers
    @discardableResult
    public func upsertContainer(projectId: Int64, name: String, shell: ShellType) throws -> Int64 {
        try db.write { db in
            var c = Container(id: nil, projectId: projectId, name: name, shell: shell, createdAt: Date(), updatedAt: Date())
            try c.save(db)
            return c.id!
        }
    }
    
    public func deleteContainer(id: Int64) throws {
        try db.write { db in
            _ = try Container.deleteOne(db, key: id)
        }
    }

    public func containers(for projectId: Int64) throws -> [Container] {
        try db.read { db in
            try Container.filter(Column("projectId") == projectId).order(Column("name")).fetchAll(db)
        }
    }

    // MARK: Commands
    @discardableResult
    public func upsertCommand(projectId: Int64, containerId: Int64?, name: String, script: String) throws -> Int64 {
        try db.write { db in
            var cmd = Command(id: nil, projectId: projectId, containerId: containerId, name: name, script: script, createdAt: Date(), updatedAt: Date())
            try cmd.save(db)
            return cmd.id!
        }
    }
    
    public func deleteCommand(id: Int64) throws {
        try db.write { db in
            _ = try Command.deleteOne(db, key: id)
        }
    }

    public func commands(for projectId: Int64, containerId: Int64? = nil) throws -> [Command] {
        try db.read { db in
            var request = Command.filter(Column("projectId") == projectId)
            if let cid = containerId {
                request = request.filter(Column("containerId") == cid)
            }
            return try request.order(Column("name")).fetchAll(db)
        }
    }

    // MARK: Aggregate
    public func loadProjectGraph(named name: String) throws -> ProjectWithChildren? {
        try db.read { db in
            guard let p = try Project.filter(Column("name") == name).fetchOne(db) else { return nil }
            let cs = try Container.filter(Column("projectId") == p.id!).fetchAll(db)
            let cmds = try Command.filter(Column("projectId") == p.id!).fetchAll(db)
            return .init(project: p, containers: cs, commands: cmds)
        }
    }
}
