import Foundation

extension String {
    func containsMatch(_ regex: String) -> (Bool, String) {
        if let match = self.range(of: regex, options: .regularExpression, range: nil, locale: nil) {
            return (true, self.substring(with: match))
        }
        
        return (false, "")
        
    }
    
    func remove(_ substring:String) -> String {
        return self.replacingOccurrences(of: substring, with: "")
    }
}
