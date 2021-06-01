//
//  ViewController.swift
//  SearchBarDropDown
//
//  Created by Don Mag on 6/1/21.
//

import UIKit

class StartViewController: UIViewController {
	var isFirstTime: Bool = true
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if isFirstTime {
			isFirstTime = false
			let vc = UIAlertController(title: "Please Note!", message: "\nThis is EXAMPLE code only!\n\nIt should not be considered\n\n\"Production Ready\"", preferredStyle: .alert)
			vc.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			present(vc, animated: true, completion: nil)
		}
	}
}

class ViewController: UIViewController {

	let searchBar = SuggestionSearchBarView()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		searchBar.translatesAutoresizingMaskIntoConstraints = false
		
		// titleView width will be auto-sized by navigationBar,
		//  but only if wider than available space
		// so, let's constrain the width to something like 10,000
		//  with less-than-required Priority
		let c = searchBar.widthAnchor.constraint(equalToConstant: 10000)
		c.priority = .defaultHigh
		c.isActive = true
		navigationItem.titleView = searchBar
		
		// give the searchBar some suggested values
		searchBar.allPossibilities = ["red", "green", "blue", "yellow"]
		
		// assign a closure so we can take action when a
		//  suggestion is selected
		searchBar.didSelect = { [weak self] str in
			if let self = self {
				let vc = UIViewController()
				switch str {
				case "red":
					vc.view.backgroundColor = .red
				case "green":
					vc.view.backgroundColor = .green
				case "blue":
					vc.view.backgroundColor = .blue
				case "yellow":
					vc.view.backgroundColor = .yellow
				default:
					vc.view.backgroundColor = .white
				}
				self.navigationController?.pushViewController(vc, animated: true)
			}
		}
		
		// assign a closure so we can take action when a
		//  the Search button is tapped
		searchBar.searchTapped = { [weak self] str in
			print("Search button was tapped....")
			if let self = self {
				// do something
			}
		}
		
	}

}

class CustomNavBar: UINavigationBar {
	
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		
		// if the titleView is not an instance of SuggestionSearchBarView
		//  just allow the default hitTest
		guard let t = topItem, t.titleView is SuggestionSearchBarView else {
			return super.hitTest(point, with: event)
		}
		
		// loop through subviews, checking hitTest until we find one
		//  this will allow tapping a view outside the bounds of this view
		for v in self.subviews.reversed() {
			if v.subviews.count > 0 {
				for subv in v.subviews {
					let p = subv.convert(point, from: self)
					let r = subv.hitTest(p, with: event)
					if r != nil {
						return r
					}
				}
			}
			let p = v.convert(point, from: self)
			let r = v.hitTest(p, with: event)
			if r != nil {
				return r
			}
		}
		
		return nil
	}
	
}

class SuggestionSearchBarView: UIView {
	
	var didSelect: ((String)->())?
	var searchTapped: ((String)->())?
	
	private let searchBar = UISearchBar()
	
	private let suggestionTableView = UITableView()
	private let tableHolderView = UIView()
	
	public var allPossibilities: [String] = []
	private var possibilities: [String] = []
	
	private var svClips: Bool = true
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}
	
	private func commonInit() -> Void {
		
		suggestionTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
		
		suggestionTableView.delegate = self
		suggestionTableView.dataSource = self
		
		searchBar.translatesAutoresizingMaskIntoConstraints = false
		suggestionTableView.translatesAutoresizingMaskIntoConstraints = false
		tableHolderView.translatesAutoresizingMaskIntoConstraints = false
		
		addSubview(searchBar)
		tableHolderView.addSubview(suggestionTableView)
		addSubview(tableHolderView)
		
		NSLayoutConstraint.activate([
			
			searchBar.topAnchor.constraint(equalTo: topAnchor),
			searchBar.leadingAnchor.constraint(equalTo: leadingAnchor),
			searchBar.trailingAnchor.constraint(equalTo: trailingAnchor),
			searchBar.bottomAnchor.constraint(equalTo: bottomAnchor),
			
			// top and height constraints for tableHolderView
			//  leading/trailing will be set in didMoveToSuperview()
			tableHolderView.topAnchor.constraint(equalTo: bottomAnchor),
			tableHolderView.heightAnchor.constraint(equalToConstant: 300),
			
			suggestionTableView.topAnchor.constraint(equalTo: tableHolderView.topAnchor),
			suggestionTableView.leadingAnchor.constraint(equalTo: tableHolderView.leadingAnchor),
			suggestionTableView.trailingAnchor.constraint(equalTo: tableHolderView.trailingAnchor),
			suggestionTableView.bottomAnchor.constraint(equalTo: tableHolderView.bottomAnchor),
			
		])
		
		hideSuggestions()
		
		// allows the tableView to show outside our bounds
		clipsToBounds = false
		
		searchBar.searchBarStyle = UISearchBar.Style.prominent
		searchBar.placeholder = "Search"
		searchBar.isTranslucent = false
		searchBar.backgroundImage = UIImage()
		
		searchBar.setShowsCancelButton(true, animated: false)
		searchBar.delegate = self
		
		// some stylizing
		suggestionTableView.backgroundColor = .white
		suggestionTableView.layer.borderColor = UIColor.gray.cgColor
		suggestionTableView.layer.borderWidth = 1.0
		
		tableHolderView.layer.shadowColor = UIColor.black.cgColor
		tableHolderView.layer.shadowRadius = 4
		tableHolderView.layer.shadowOpacity = 0.6
		tableHolderView.layer.shadowOffset = CGSize(width: 0, height: 2)
		tableHolderView.layer.masksToBounds = false
		
	}
	
	override func didMoveToSuperview() {
		if let sv = superview {
			NSLayoutConstraint.activate([
				
				// if we want the tableView width to match the searchField
				//tableHolderView.leadingAnchor.constraint(equalTo: searchBar.searchTextField.leadingAnchor),
				//tableHolderView.trailingAnchor.constraint(equalTo: searchBar.searchTextField.trailingAnchor),
				
				// if we want the tableView to span the full view width
				tableHolderView.leadingAnchor.constraint(equalTo: sv.leadingAnchor),
				tableHolderView.trailingAnchor.constraint(equalTo: sv.trailingAnchor),
				
			])
			
			// save .clipsToBounds state of superview so we can
			//  restore it when hiding the table view
			svClips = sv.clipsToBounds
		}
	}
	
	func updateTable() -> Void {
		let s = searchBar.text ?? ""
		if s.isEmpty {
			possibilities = allPossibilities
		} else {
			possibilities = allPossibilities.filter {$0.contains(s.lowercased())}
		}
		suggestionTableView.reloadData()
	}
	
	func showSuggestions() {
		// we need to set .clipsToBounds = false on the superView
		if let sv = superview {
			sv.clipsToBounds = false
		}
		tableHolderView.isHidden = false
		updateTable()
	}
	
	func hideSuggestions() {
		// set .clipsToBounds on the superView
		//  back to its original state
		if let sv = superview {
			sv.clipsToBounds = svClips
		}
		tableHolderView.isHidden = true
	}
	
	override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
		
		// loop through subviews, checking hitTest until we find one
		//  this will allow tapping a view outside the bounds of this view
		for v in subviews.reversed() {
			let p = v.convert(point, from: self)
			let r = v.hitTest(p, with: event)
			if r != nil {
				return r
			}
		}
		
		return nil
		
	}
	
}

// MARK: searchBar Delegate funcs
extension SuggestionSearchBarView: UISearchBarDelegate {
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		endEditing(true)
	}
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		let s = searchBar.text ?? ""
		print("Search Button Tapped:", s)
		// use the closure to tell the controller that the Search button was tapped
		searchTapped?(s)
	}
	
	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		showSuggestions()
	}
	
	func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
		hideSuggestions()
	}
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		updateTable()
	}
	
}

// MARK: tableView DataSource and Delegate funcs
extension SuggestionSearchBarView: UITableViewDataSource, UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return possibilities.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = suggestionTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		cell.backgroundColor = UIColor(white: 0.25, alpha: 0.75)
		if traitCollection.userInterfaceStyle == .light {
			cell.backgroundColor = UIColor(white: 1.0, alpha: 0.75)
		}
		cell.textLabel?.text = possibilities[indexPath.row]
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		print("Selected:", possibilities[indexPath.row])
		tableView.deselectRow(at: indexPath, animated: true)
		endEditing(true)
		// use the closure to tell the controller that a row was selected
		didSelect?(possibilities[indexPath.row])
	}
	
}
