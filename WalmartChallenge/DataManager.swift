//
//  DataManager.swift
//  WalmartChallenge
//
//  Created by Matthew Garner on 5/25/17.
//  Copyright © 2017 Matthew Garner. All rights reserved.
//

import UIKit

protocol DataManagerDelegate: class {
	func managerHasUpdates()
	func retrievalFailedWith(error: String)
}

final class DataManager : NSObject {
		
	static var sharedInstance: DataManager = DataManager()
	
	let baseUrl = "https://walmartlabs-test.appspot.com/_ah/api/walmart/v1"
	
	weak var delegate:DataManagerDelegate?
	
	var session: URLSession?
	
	var idNumber = 0
	
	var productArray = [Product]()
	
	var totalProducts: Int!
	
	var pageSize = 30

	var pageNumber = 1
	
	var currentSortOption = sortOptions.reset
	
	
	// MARK: public methods
	
	func loadProducts() {
		DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
			self.retrieveProducts()
		}
	}
	
	func loadMoreProducts() {
		let remainingProducts = totalProducts - pageNumber * pageSize
		if remainingProducts < pageSize {
			pageSize = remainingProducts
		}
		pageNumber += 1
		loadProducts()
	}
	
	func hasMore() -> Bool {
		if totalProducts > productArray.count {
			return true
		}
		return false
	}
	
	func sortWith(option: String) {
		currentSortOption = option
		productArray = sort(array: productArray)
	}

	func sort(array: [Product]) -> [Product] {
		var tempArray:[Product]
		switch currentSortOption {
		case sortOptions.priceHigh:
			tempArray = array.sorted(by: { $0.price > $1.price })
			
		case sortOptions.priceLow:
			tempArray = array.sorted(by: { $0.price < $1.price })
			
		case sortOptions.ratingHigh:
			tempArray = array.sorted(by: { $0.reviewRating > $1.reviewRating })
			
		case sortOptions.ratingLow:
			tempArray = array.sorted(by: { $0.reviewRating < $1.reviewRating })
			
		default: // reset
			tempArray = array.sorted(by: { $0.productIdNumber < $1.productIdNumber })
		}
		return tempArray
	}
	
	func handleAppResignation() {
		
		session?.finishTasksAndInvalidate()
	}
	
	
	// MARK: fileprivate session-related methods
	
	fileprivate func retrieveProducts() {
		// make query
		let url = URL(string: self.baseUrl + "/walmartproducts/\(dataKeys.kAPIKey)/\(pageNumber)/\(pageSize)")
		
		// loading
		DispatchQueue.main.async(){
			UIApplication.shared.isNetworkActivityIndicatorVisible = true
		}
		
		// create request
		let urlRequest = URLRequest(url: url!)
		
		// if necessary, create session
		if session == nil {
			let config = URLSessionConfiguration.default
			session = URLSession(configuration: config)
		}
		
		// make request
		let task = session?.dataTask(with: urlRequest, completionHandler: {(data, response, error) in
			
			guard error == nil else {
				DispatchQueue.main.async(){
					self.delegate?.retrievalFailedWith(error: error!.localizedDescription)
				}
				return
			}
			
			self.retrievalSucceededWith(data: data!)
		})
		task?.resume()
	}
	
	fileprivate func retrievalSucceededWith(data: Data) {
		// process the received data
		processResults(data: data)
		
		// notify completion
		DispatchQueue.main.async(){
			UIApplication.shared.isNetworkActivityIndicatorVisible = false
			self.delegate?.managerHasUpdates()
		}
	}
		
	
	// MARK: fileprivate data transformation-related methods
	
	fileprivate func processResults(data: Data) {
		do {
			guard let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
				return
			}
			// parse results
			if let products: Array = result[dataKeys.kProductsKey] as? Array<Dictionary<String, Any>> {
				var tempArray = [Product]()
				for product in products {
					// create Product and add to array
					let newProduct = Product(dictionary: product, id: idNumber)
					tempArray.append(newProduct)
					idNumber += 1
				}
				
				if currentSortOption != sortOptions.reset {
					tempArray = sort(array: tempArray)
				}
				self.productArray.append(contentsOf: tempArray)
			}
			
			if let total: Int = result[dataKeys.kTotalProductsKey] as? Int {
				totalProducts = total
			}

			if let size: Int = result[dataKeys.kPageSizeKey] as? Int {
				pageSize = size
			}

			if let num: Int = result[dataKeys.kPageNumberKey] as? Int {
				pageNumber = num
			}
			
		} catch  {
			delegate?.retrievalFailedWith(error: "Data Processing Error")
			return
		}
	}
}
