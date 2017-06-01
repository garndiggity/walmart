//
//  ProductDetailViewController.swift
//  WalmartChallenge
//
//  Created by Matthew Garner on 5/25/17.
//  Copyright © 2017 Matthew Garner. All rights reserved.
//

import UIKit

class ProductDetailViewController: UIViewController {
	
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var productImageView: UIImageView!
	@IBOutlet weak var priceLabel: UILabel!
	@IBOutlet weak var stockLabel: UILabel!
	@IBOutlet weak var ratingLabel: UILabel!
	@IBOutlet weak var descriptionTextView: UITextView!
	@IBOutlet weak var descriptionViewHeight: NSLayoutConstraint!
	
	var product: Product!
	
	
	// MARK: View-related Methods
	
	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Details"
		
		nameLabel.text = product.productName
		productImageView.image = UIImage(named: "placeholder")
		if let string = product.productImageURLString, !(product.productImageURLString?.isEmpty)! {
			productImageView.downloadImageFrom(link: string, contentMode: .scaleAspectFit)
		}
		productImageView.layer.shadowColor = UIColor.black.cgColor
		productImageView.layer.shadowOpacity = 0.8
		productImageView.layer.shadowOffset = .zero
		productImageView.layer.shadowRadius = 5
		
		priceLabel.text = product.priceString
		stockLabel.text = product.userFriendlyStockStatus
		stockLabel.textColor = product.inStock ? UIColor(red:0.149, green:0.5764, blue:0.1686, alpha:1.0) : .red
		
		ratingLabel.text = product.userFriendlyRating + " (\(product.reviewCount) Reviews)"

		descriptionTextView.text = "Description:\n\(product.shortDescription)\n\n\(product.longDescription)"
	}
	
	override func viewDidLayoutSubviews() {
		productImageView.layer.shadowPath = UIBezierPath(rect: productImageView.bounds).cgPath

		let fixedWidth = descriptionTextView.frame.size.width
		let newSize = descriptionTextView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
		var newFrame = descriptionTextView.frame
		newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
		descriptionTextView.frame = newFrame;
		descriptionViewHeight.constant = newFrame.size.height
		
		scrollView.contentSize = CGSize(width:scrollView.contentSize.width, height:descriptionTextView.frame.origin.y + descriptionTextView.frame.size.height + 20)
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		coordinator.animate(alongsideTransition: nil) { _ in
			self.productImageView.layer.shadowPath = UIBezierPath(rect: self.productImageView.bounds).cgPath
		}
	}
}
