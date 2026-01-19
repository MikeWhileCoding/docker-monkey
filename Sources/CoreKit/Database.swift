//
//  Database.swift
//  Dockey
//
//  Created by Mike de Groot on 25/08/2025.
//

import Foundation
import GRDB

public final class DatabaseProvider {
    public static let shared = try! DatabaseProvider()

    public let dbQueue: DatabaseQueue

    private init() throws {
        let url = try Self.defaultDBURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
            try db.execute(sql: "PRAGMA journal_mode = WAL")
        }
        dbQueue = try DatabaseQueue(path: url.path, configuration: config)
        try migrator.migrate(dbQueue)
    }

    static func defaultDBURL() throws -> URL {
        let appSup = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        )
        return appSup.appendingPathComponent("Dockey/Core/data.sqlite")
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "project") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull().unique(onConflict: .replace)
                t.column("rootPath", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            try db.create(table: "container") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("projectId", .integer).notNull().indexed()
                    .references("project", onDelete: .cascade)
                t.column("name", .text).notNull()
                t.column("shell", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.uniqueKey(["projectId", "name"], onConflict: .replace)
            }
            try db.create(table: "command") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("projectId", .integer).notNull().indexed()
                    .references("project", onDelete: .cascade)
                t.column("containerId", .integer).indexed().references("container", onDelete: .setNull)
                t.column("name", .text).notNull()
                t.column("script", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.uniqueKey(["projectId", "name"], onConflict: .replace)
            }
        }

        return migrator
    }
}

