import Foundation
import Guaka

var rootCommand = Command(
  usage: "Graphical", configuration: configuration, run: execute)


private func configuration(command: Command) {

  command.add(flags: [
    // Add your flags here
    ]
  )

  // Other configurations
}

private func execute(flags: Flags, args: [String]) {
  // Execute code here
    print("Retrieving build settings for \(args[0])")
    
    
    var shouldExit = false
    findDeps(at: args[0]) { _ in
        defer {
            shouldExit = true
        }
        

    }
    autoreleasepool {
        let runLoop = RunLoop.current
        while (!shouldExit && (runLoop.run(mode: .defaultRunLoopMode, before: Date.distantFuture))) {}
    }
    
}
