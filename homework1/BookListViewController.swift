import Foundation
import UIKit

// MARK: - Book List (View and Controller)

class BookListViewController: UITableViewController {
    let bookStore = BookStore()

    let loadingView = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadingView.activityIndicatorViewStyle = .gray
        self.loadingView.hidesWhenStopped = true
        self.navigationController?.view.addSubview(self.loadingView)
        self.loadingView.startAnimating()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.loadingView.center = (self.navigationController?.view.center)!
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        weak var weakSelf = self

        self.bookStore.fetchData { (error:Error?) -> (Void) in

            if let aError = error {
                let alert = UIAlertController(title: "Fetch data error", message: "Error:\(aError.localizedDescription)", preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler:nil)

                alert.addAction(action)
                weakSelf?.present(alert, animated: true, completion: nil)
            }

            weakSelf?.tableView.reloadData()
            weakSelf?.loadingView.stopAnimating()
            weakSelf?.navigationItem.title = "Book Shopping Cart ($\(weakSelf!.bookStore.totalBookPrice))"
        }
    }
    
    // MARK: Table View Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.bookStore.authors.count
        case 1:
            return self.bookStore.books.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Authors"
        case 1:
            return "Books"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "BookCell"
        let cell = (tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ??
            UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier))
        
        if indexPath.section == 0 {
            self.setup(authorCell: cell, at: indexPath.row)
        } else if indexPath.section == 1 {
            self.setup(bookCell: cell, at: indexPath.row)
        }
        
        return cell
    }
    
    func setup(authorCell cell: UITableViewCell, at index: Int) {
        cell.textLabel!.text = self.bookStore.authors[index]
    }
    
    func setup(bookCell cell: UITableViewCell, at index: Int) {
        let book = self.bookStore.books[index]
        cell.textLabel!.text = "\(book.title) ($\(book.price))"
        cell.detailTextLabel!.text = book.author
    }
    
    // MARK: Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }


}
