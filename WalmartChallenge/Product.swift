//
//  Product.swift
//  WalmartChallenge
//
//  Created by Matthew Garner on 5/25/17.
//  Copyright © 2017 Matthew Garner. All rights reserved.
//

import UIKit

struct dataKeys {
	static let kAPIKey = "70c9a3bd-0460-4fd8-be66-56a65b927804"
	static let kProductsKey = "products"
	static let kTotalProductsKey = "totalProducts"
	static let kPageNumberKey = "pageNumber"
	static let kPageSizeKey = "pageSize"
	
	static let kProductIDKey = "productId"
	static let kProductNameKey = "productName"
	static let kProductShortDescKey = "shortDescription"
	static let kProductLongDescKey = "longDescription"
	static let kProductPriceKey = "price"
	static let kProductImageURLKey = "productImage"
	static let kProductReviewRatingKey = "reviewRating"
	static let kProductReviewCountKey = "reviewCount"
	static let kProductInStockKey = "inStock"
}

struct Product {
	
	var productIdNumber: Int!
	var productId: String?
	var productName = ""
	var shortDescription = ""
	var longDescription = ""
	var priceString = "No Price Listed"
	var price: Double!
	var productImageURLString: String?
	var reviewRating = 0.0
	var userFriendlyRating: String!
	var reviewCount = 0
	var inStock: Bool = false
	var userFriendlyStockStatus: String!
	
	init(dictionary: Dictionary<String, Any>, id: Int) {
		
		productIdNumber = id
		
		if let value = dictionary[dataKeys.kProductIDKey] {
			productId = value as? String
		}
		
		if let value = dictionary[dataKeys.kProductNameKey] {
			let encodedString = value as? String
			productName = String(htmlEncodedString: encodedString!)
		}
		
		if let value = dictionary[dataKeys.kProductShortDescKey] {
			let encodedString = value as? String
			shortDescription = String(htmlEncodedString: encodedString!)
		}

		if let value = dictionary[dataKeys.kProductLongDescKey] {
			let encodedString = value as? String
			longDescription = String(htmlEncodedString: encodedString!)
		}
		
		if let value = dictionary[dataKeys.kProductPriceKey] {
			priceString = (value as? String)!
			let no$String = priceString.replacingOccurrences(of: "$", with: "")
			let noCommaString = no$String.replacingOccurrences(of: ",", with: "")
			price = Double(noCommaString)
		}
		
		if let value = dictionary[dataKeys.kProductImageURLKey] {
			productImageURLString = value as? String
		}

		if let value = dictionary[dataKeys.kProductReviewRatingKey] {
			let rawDouble = value as? Double
			reviewRating = (rawDouble! * 100).rounded() / 100
		}

		userFriendlyRating = "\(reviewRating) of 5.0"
		
		if let value = dictionary[dataKeys.kProductReviewCountKey] {
			reviewCount = (value as? Int)!
		}

		if let value = dictionary[dataKeys.kProductInStockKey] {
			inStock = value as! Bool
		}
		
		userFriendlyStockStatus = inStock ? "In Stock" : "Backordered"
	}
}

extension String {
	init(htmlEncodedString: String) {
		self.init()
		let specCharRemovedString = htmlEncodedString.replacingOccurrences(of: "�", with: "")
		guard let encodedData = specCharRemovedString.data(using: .utf8) else {
			self = htmlEncodedString
			return
		}
		
		let attributedOptions: [String : Any] = [
			NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
			NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue
		]
		
		do {
			let attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
			self = attributedString.string
		} catch {
			print("Error: \(error)")
			self = htmlEncodedString
		}
	}
}


