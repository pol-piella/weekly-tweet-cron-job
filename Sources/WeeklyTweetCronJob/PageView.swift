import Foundation

struct PageView: Decodable {
    var uniques: Int
    let pathname: String
    
    enum CodingKeys: CodingKey {
        case uniques
        case pathname
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let uniquesString = try container.decode(String.self, forKey: .uniques)
        self.uniques = Int(uniquesString)!
        self.pathname = try container.decode(String.self, forKey: .pathname)
            .replacingOccurrences(of: "/", with: "")
    }
}
