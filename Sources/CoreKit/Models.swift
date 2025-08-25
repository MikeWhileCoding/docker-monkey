//
//  Models.swift
//  Dockey
//
//  Created by Mike de Groot on 25/08/2025.
//

import Foundation
import GRDB

public enum ShellType: String, Codable, CaseIterable {
    case bash = "bash"
    case zsh = "zsh"
    case sh = "/bin/sh"
}

public struct Project: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable {
    public var id: Int64?
    public var name: String
    public var rootPath: String
    public var createdAt: Date
    public var updatedAt: Date
}

public struct Container: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable {
    public var id: Int64?
    public var projectId: Int64
    public var name: String
    public var shell: ShellType
    public var createdAt: Date
    public var updatedAt: Date
}

public struct Command: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable {
    public var id: Int64?
    public var projectId: Int64
    public var containerId: Int64?   // nil = run from project root
    public var name: String
    public var script: String        // what to execute
    public var createdAt: Date
    public var updatedAt: Date
}
