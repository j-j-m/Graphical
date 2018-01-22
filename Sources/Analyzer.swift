import Foundation
import Progress


typealias RawDep = [String:Any]
typealias DependencyGraphRep = [String:[String:Any]]
class Analyzer {
    
    struct Regex {
        static let keywords = "^(Any|AnyBidirectionalCollection|AnyBidirectionalIndex|AnyClass|AnyForwardCollection|AnyForwardIndex|AnyObject|AnyRandomAccessCollection|AnyRandomAccessIndex|AnySequence|Array|ArraySlice|AutoreleasingUnsafeMutablePointer|BOOL|Bool|BooleanLiteralType|CBool|CChar|CChar16|CChar32|CDouble|CFloat|CInt|CLong|CLongLong|COpaquePointer|CShort|CSignedChar|CUnsignedChar|CUnsignedInt|CUnsignedLong|CUnsignedLongLong|CUnsignedShort|CVaListPointer|CWideChar|Character|ClosedInterval|ClusterType|CollectionOfOne|ContiguousArray|DISPATCH_|Dictionary|DictionaryGenerator|DictionaryIndex|DictionaryLiteral|Double|EmptyGenerator|EnumerateGenerator|EnumerateSequence|ExtendedGraphemeClusterType|FlattenBidirectionalCollection|FlattenBidirectionalCollectionIndex|FlattenCollectionIndex|FlattenSequence|Float|Float32|Float64|FloatLiteralType|GeneratorSequence|HalfOpenInterval|IndexingGenerator|Int|Int16|Int32|Int64|Int8|IntMax|IntegerLiteralType|JoinGenerator|JoinSequence|LazyCollection|LazyFilterCollection|LazyFilterGenerator|LazyFilterIndex|LazyFilterSequence|LazyMapCollection|LazyMapGenerator|LazyMapSequence|LazySequence|LiteralType|ManagedBufferPointer|Mirror|MutableSlice|ObjectIdentifier|Optional|PermutationGenerator|Range|RangeGenerator|RawByte|Repeat|ReverseCollection|ReverseIndex|ReverseRandomAccessCollection|ReverseRandomAccessIndex|ScalarType|Set|SetGenerator|SetIndex|Slice|StaticString|StrideThrough|StrideThroughGenerator|StrideTo|StrideToGenerator|String|String.CharacterView|String.CharacterView.Index|String.UTF16View|String.UTF16View.Index|String.UTF8View|String.UTF8View.Index|String.UnicodeScalarView|String.UnicodeScalarView.Generator|String.UnicodeScalarView.Index|StringLiteralType|UInt|UInt16|UInt32|UInt64|UInt8|UIntMax|UTF16|UTF32|UTF8|UnicodeScalar|UnicodeScalarType|Unmanaged|UnsafeBufferPointer|UnsafeBufferPointerGenerator|UnsafeMutableBufferPointer|UnsafeMutablePointer|UnsafePointer|Void|Zip2Generator|Zip2Sequence|abs|alignof|alignofValue|anyGenerator|anyGenerator|assert|assertionFailure|debugPrint|debugPrint|dispatch_|dump|dump|fatalError|getVaList|isUniquelyReferenced|isUniquelyReferencedNonObjC|isUniquelyReferencedNonObjC|max|max|min|min|numericCast|numericCast|numericCast|numericCast|precondition|preconditionFailure|print|print|readLine|sizeof|sizeofValue|strideof|strideofValue|swap|transcode|unsafeAddressOf|unsafeBitCast|unsafeDowncast|unsafeUnwrap|withExtendedLifetime|withExtendedLifetime|withUnsafeMutablePointer|withUnsafeMutablePointers|withUnsafeMutablePointers|withUnsafePointer|withUnsafePointers|withUnsafePointers|withVaList|withVaList|zip)$"
        
        static let framework = "^(CA|CF|CG|CI|CL|kCA|NS|UI)"
        
        static let valid = "^(<\\s)?\\w"
        
    }
    
    class func generate(_ deps: [String], path: String) -> DependencyGraphRep {
        
        var results = [RawDep]()
        
        let depCount = deps.count
        for i in Progress(0..<depCount) {
            let d = deps[i]
            
            
            ProgressBar.defaultConfiguration = [ProgressString(string: "Parse:"), ProgressBarLine(),ProgressString(string: " | \(i+1)/\(depCount) | \(i < depCount - 1 ? "Parsing dependency info from \(d)" : "✅ Parse Complete")")]
            let p = path+d
            if let depfile = CFileWrapper.readFrom(p) {
                do{
                    let dep = try YamlParser.parse(depfile)
                    results.append(dep)
                }
                catch {
                    print("could not parse yaml")
                }
            }
            else {
                print("could not open file")
            }
            
        }
        
        var graphRep = DependencyGraphRep()
        
        var usage = [String:[String]]()
        
        for r in results {
            
            var dependencies = [String]()
            
            if let provides = r["provides-top-level"] as? [String],
                let nominals = r["provides-nominal"] as? [String] {
                
                if let depends = r["depends-top-level"] as? [String],
                    let dependsMember = r["depends-member"] as? [Any] {
                    
                    for (name, nominal) in zip(provides, nominals) {
                        
                        for member in dependsMember {
                            if let m = member as? [String] {
                                if m[0] == nominal && depends.contains(m[1]) && isValidDep(m[1]) {
                                    dependencies.append(m[1])
                                    var u = usage[m[1]] ?? [String]()
                                    u.append(name)
                                    usage[m[1]] = u
                                }
                            }
                        }
                        
                        var structure = "none"
                        let first = nominal.characters.first
                        
                        if nominal.hasPrefix("C"){
                            structure = "class"
                        }
                        else if nominal.hasPrefix("V"){
                            structure = "struct"
                        }
                        else if nominal.hasPrefix("O"){
                            structure = "enum"
                        }
                        else if nominal.hasPrefix("P"){
                            if nominal.containsMatch(name).0 {
                                structure = "protocol"
                            }
                            else {
                                structure = "typealias"
                            }
                        }
                        
                       
                        
                       
                        
                        
                        var item: [String: Any] = [
                            "name": name,
                            "nominal": nominal,
                            "structure": structure,
                            "dependencies" : dependencies,
                            "usage" : usage[name] ?? []
                        ]
                        
                        
                        graphRep[name] = item
                        
                    }
                }
                
            }
            
        }
        
        
        return graphRep
        
    }
    
    
    class func isValidDep(_ dep: String) -> Bool {
        return dep.containsMatch(Regex.valid).0 && !isKeyword(dep) && !isFramework(dep)
    }
    
    class func isFramework(_ dep: String) -> Bool {
        return dep.containsMatch(Regex.framework).0
    }
    
    class func isKeyword(_ dep: String) -> Bool {
        
        return dep.containsMatch(Regex.keywords).0
    }
    
}
