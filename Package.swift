import PackageDescription
let package = Package(
  name: "Graphical",
  dependencies: [
    .Package(url: "https://github.com/oarrabi/Guaka.git", majorVersion: 0),
    .Package(url: "https://github.com/kareman/SwiftShell.git", majorVersion: 3),
    .Package(url: "https://github.com/johnsundell/files.git", majorVersion: 1),
    .Package(url: "https://github.com/jkandzi/Progress.swift", majorVersion: 0),
    .Package(url: "https://github.com/jpsim/Yams.git", majorVersion: 0)
    ]
)
