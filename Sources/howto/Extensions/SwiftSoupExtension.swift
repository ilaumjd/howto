import Foundation
import SwiftSoup

/// Extends SwiftSoup's `Element` with HTML-decoded text extraction.
extension Element {
    /// Returns the inner HTML of this element with HTML entities unescaped.
    /// - Returns: The decoded text content.
    /// - Throws: A SwiftSoup error if the HTML is malformed.
    func htmlDecoded() throws -> String {
        let html = try self.html()
        return try Entities.unescape(string: html, strict: true)
    }
}
