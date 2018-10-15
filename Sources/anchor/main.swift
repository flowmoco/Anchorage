import Foundation
import Anchorage_CLI

let commandName = "anchor"

main(withArguments: ProcessInfo.processInfo.arguments, commandName: commandName, overview: "The \(commandName) command is used to manage a docker swarm cluster.")
