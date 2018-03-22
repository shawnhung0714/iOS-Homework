import UIKit

// MARK: - Book Store (Model and Main class)

public class BookStore {

    // MARK: Properties

    var books: [Book] = []
    
    var totalBookPrice: Double = 0
    
    var authors: [String] = []

    let bookURL = "http://bit.do/eaaqu"
    
    // MARK: Function interfacesc

    public func fetchData(complete: @escaping () -> ()){
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            // Get book from bookGetter
            var books = [Book]()
            var totalBookPrice = 0.0
            var authors = Set<String>()

            do {
                try books = self.getBookData(urlText: self.bookURL).map { (bookDict:[String: String]) -> Book in
                    let book = Book(title:bookDict["title"]!, author: bookDict["author"]!, price:Double(bookDict["price"]!)!)
                    return book
                };
            } catch {
                print("get books error:\(error)")
            }

            // Sort books
            books.sort()
            // Retrieive authors and prices

            for book in books {
                authors.insert(book.author)
            }

            totalBookPrice = books.reduce(0, { result, book in
                result + book.price
            })

            //assign value to property
            self.books = books
            self.totalBookPrice = totalBookPrice
            self.authors = Array(authors)

            DispatchQueue.main.async {
                complete()
            }
        }
    }

    func getBookData(urlText: String) throws -> [[String: String]]{
        guard let url = URL.init(string: urlText) else {
            return []
        }

        let data = try Data.init(contentsOf: url)
        let jsonData = try JSONSerialization.jsonObject(with: data, options: [])
        guard let bookData: [[String : String]] = jsonData as? [[String : String]] else {
            return []
        }

        return bookData
    }
}


