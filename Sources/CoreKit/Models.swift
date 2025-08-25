//
//  Models.swift
//  Dockey
//
//  Created by Mike de Groot on 25/08/2025.
//

import Foundation
import GRDB

public enum ShellType: String, Codable, CaseIterable {
    case zsh, bash, fish
}

public struct Project: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Equatable {
    public static let databaseTableName = "project" // be explicit
    public var id: Int64?
    public var name: String
    public var rootPath: String
    public var createdAt: Date
    public var updatedAt: Date

    // make sure inserts populate `id`
    public mutating func didInsert(with rowID: Int64, for column: String?) {
        self.id = rowID
    }
}

public struct Container: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Equatable {
    public static let databaseTableName = "container"
    public var id: Int64?
    public var projectId: Int64
    public var name: String
    public var shell: ShellType
    public var createdAt: Date
    public var updatedAt: Date

    public mutating func didInsert(with rowID: Int64, for column: String?) {
        self.id = rowID
    }
}

public struct Command: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Equatable {
    public static let databaseTableName = "command"
    public var id: Int64?
    public var projectId: Int64
    public var containerId: Int64?   // nil = run from project root
    public var name: String
    public var script: String
    public var createdAt: Date
    public var updatedAt: Date

    public mutating func didInsert(with rowID: Int64, for column: String?) {
        self.id = rowID
    }
}
