//
//  SortView.swift
//  WalmartChallenge
//
//  Created by Matthew Garner on 5/31/17.
//  Copyright © 2017 Matthew Garner. All rights reserved.
//

import UIKit

struct sortOptions {
	static let priceHigh = "Price (High to Low)"
	static let priceLow = "Price (Low to High)"
	static let ratingHigh = "Rating (High to Low)"
	static let ratingLow = "Rating (Low to High)"
	static let reset = "Reset"
}

protocol SortViewDelegate: class {
	func sortOptionSelected(option: String)
}

class SortView: UIView, UITableViewDataSource, UITableViewDelegate {
	
	weak var delegate:SortViewDelegate?

	var sortTableView:UITableView!
	
	var sortOptionsArray = [sortOptions.priceHigh, sortOptions.priceLow, sortOptions.ratingHigh, sortOptions.ratingLow]
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.layer.shadowColor = UIColor.black.cgColor
		self.layer.shadowOpacity = 0.8
		self.layer.shadowOffset = .zero
		self.layer.shadowRadius = 2
		self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
		
		sortTableView = UITableView(frame:CGRect(x:0, y:0, width:frame.size.width, height:frame.size.height))
		sortTableView.dataSource = self
		sortTableView.delegate = self
		sortTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
		self.addSubview(sortTableView)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func updateViewSize() {

		var height = self.frame.size.height
		if sortOptionsArray.count == 5 {
			height = 220.0
		} else {
			height = 176.0
		}
		self.frame.size.height = height
		self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
		sortTableView.frame.size.height = height
		sortTableView.reloadData()
	}
	
	
	// MARK: UITableViewDataSource methods
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sortOptionsArray.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) 
		cell.textLabel?.text = sortOptionsArray[indexPath.row]
		return cell
	}
	
	
	// MARK: UITableViewDelegate methods
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let option = sortOptionsArray[indexPath.row]
		
		if option == sortOptions.reset {
			sortOptionsArray.removeLast()
		} else if sortOptionsArray.count == 4 {
			sortOptionsArray.append(sortOptions.reset)
		}
		delegate?.sortOptionSelected(option: option)
		tableView.deselectRow(at: indexPath, animated: true)
		updateViewSize()
	}
}
