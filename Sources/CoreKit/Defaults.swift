//
//  Defaults.swift
//  Dockey
//
//  Created by Mike de Groot on 25/08/2025.
//

import Foundation

public struct Defaults: Codable, Equatable {
    public var defaultShell: ShellType
    public var defaultProjectRoot: String

    public init(defaultShell: ShellType = .bash,
                defaultProjectRoot: String = FileManager.default.currentDirectoryPath) {
        self.defaultShell = defaultShell
        self.defaultProjectRoot = defaultProjectRoot
    }
}

public enum DefaultsStore {
    private static func url() throws -> URL {
        let appSup = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        )
        try FileManager.default.createDirectory(at: appSup.appendingPathComponent("Dockey/Core"), withIntermediateDirectories: true)
        return appSup.appendingPathComponent("Dockey/Core/config.json")
    }

    public static func load() -> Defaults {
        do {
            let data = try Data(contentsOf: try url())
            return try JSONDecoder().decode(Defaults.self, from: data)
        } catch {
            return Defaults()
        }
    }

    public static func save(_ d: Defaults) throws {
        let data = try JSONEncoder().encode(d)
        try data.write(to: try url(), options: .atomic)
    }
}
