import ArgumentParser
import CoreKit

@main
struct DockeyCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "dockey",
        abstract: "Dockey command-line tool"
    )

    func run() throws {
        let (_, out, _) = try Shell.run("/bin/echo", ["Hello from dockey"])
        print(out)
    }
}
