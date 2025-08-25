import ArgumentParser
import CoreKit

struct DockeyCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "dockey",
        abstract: "Dockey command-line tool",
        subcommands: [ProjectCLI.self]
    )
}

DockeyCLI.main()
