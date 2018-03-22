import Foundation

extension Book : Comparable {
    static public func < ( book1: Book, book2: Book) -> Bool {
        return book1.title.caseInsensitiveCompare(book2.title) == .orderedAscending
    }

    static public func == ( book1: Book, book2: Book) -> Bool {
        return book1.title.caseInsensitiveCompare(book2.title) == .orderedSame
    }

    static public func > ( book1: Book, book2: Book) -> Bool {
        return book1.title.caseInsensitiveCompare(book2.title) == .orderedDescending
    }
}
