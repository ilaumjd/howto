import Foundation
import SwiftSoup

extension Element {
    func htmlDecoded() throws -> String {
        let html = try self.html()
        return try Entities.unescape(string: html, strict: true)
    }
}
