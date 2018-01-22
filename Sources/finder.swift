import Darwin
import Foundation
import SwiftShell
import Files


func findDerivedData(at projectPath: String, completion: @escaping (String) -> Void ) {
    
    
    let args = ["-project", projectPath,
                "-showBuildSettings",
                "build",
                "CODE_SIGNING_ALLOWED=NO",
                "CODE_SIGNING_REQUIRED=NO"]
    
    let name = "xcodebuild"
    
    var derivedDataPath:String?
    var projectName:String?
    // var targetName:String?
    
    let command = runAsync(name, args).onCompletion { command in
        if let d = derivedDataPath, let p = projectName {
            //            let fullPath = "\(d)/\(p).build/**/\(t)*.build"
            let fullPath = "\(d)/\(p).build"
            
            print("Derived data path: "+fullPath)
            completion(fullPath)
            
        }
    }
    
    let rootPathToken = "OBJROOT = "
    let nameToken = "PROJECT_NAME = "
    //    let targetToken = "TARGET_NAME = "
    
    command.stdout.onOutput { stdout in
        
        while let text = stdout.readSome() {
            
            
            let rootPathParse = text.containsMatch(rootPathToken+"(.*)")
            if rootPathParse.0 {
                derivedDataPath = rootPathParse.1.remove(rootPathToken).remove(".noindex")
            }
            
            
            let projectNameParse = text.containsMatch(nameToken+"(.*)")
            if projectNameParse.0 {
                projectName = projectNameParse.1.remove(nameToken)
            }
            
            //            let targetNameParse = text.containsMatch(targetToken+"(.*)")
            //            if targetNameParse.0 {
            //                targetName = targetNameParse.1.remove(targetToken)
            //            }
            
        }
        
    }
    
    do {
        try command.finish() // wait for it to finish.
    }
    catch {
        print("something went wrong parsing project build settings")
    }
    
    
}



func findDeps(at projectPath: String, _ completion: @escaping () -> Void) {
    findDerivedData(at: projectPath){ string in
        
        print(string)
        searchFiles(at: string, completion)
    }
}


func searchFiles(at path:String, _ completion: @escaping () -> Void) {
    do {
        let folder = try Folder(path: path)
        let grandparent = folder.parent!
        
        
        // print("Searching in \(folder.path)")
        
        folder.makeSubfolderSequence(recursive: false).forEach { f in
            // print("Name : \(f.name), parent: \(f.parent!.name)")
            
            if f.path.containsMatch("x86_64").0{
                print("found deps folder")
                
                printDirectoryContents(f.path, name:grandparent.name)
                completion()
            }
            else {
                searchFiles(at: f.path, completion)
            }
        }
        
    }
    catch {
        print("error \(error)")
    }
    
    
    
}




func printDirectoryContents(_ path: String, name: String) {
    
    
    let fileManager = FileManager.default
    let rootPath = path
    print(rootPath)
    // Enumerate the directory tree (which likely recurses internally)...
    var deps = [String]()
    if let enumerator:FileManager.DirectoryEnumerator = fileManager.enumerator(atPath:rootPath){
        while let element = enumerator.nextObject() as? String {
            if element.hasSuffix("swiftdeps") { // checks the extension
                deps.append(element)
            }
        }
    }
    
    
    let depGraph = Analyzer.generate(deps, path: rootPath)
    
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: depGraph, options: .prettyPrinted)
        if let jsonString = String(bytes: jsonData, encoding: String.Encoding.utf8) {
            CFileWrapper.writeTo("./deps_"+name+".json", content:jsonString)
        }
        
    } catch {
        print("unable to create json")
    }
    
    
}



