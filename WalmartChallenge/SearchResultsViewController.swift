//
//  SearchResultsViewController.swift
//  WalmartChallenge
//
//  Created by Matthew Garner on 5/25/17.
//  Copyright © 2017 Matthew Garner. All rights reserved.
//

import UIKit

class SearchResultsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DataManagerDelegate, SortViewDelegate {
	
	@IBOutlet weak var resultsTableView: UITableView!
	@IBOutlet weak var resultsCountLabel: UILabel!
	@IBOutlet weak var sortButton: UIButton!
	@IBOutlet weak var sortBarTop: NSLayoutConstraint!
	
	let dataManager = DataManager.sharedInstance
	
	var progressHUD: ProgressHUD?
	
	var alert: UIAlertController?
	var retryCount = 0
	
	var sortView: SortView?
	var sortEnclosingView: UIView?

	
	// MARK: View-related methods

	override func viewDidLoad() {
		super.viewDidLoad()

		resultsTableView.register(SearchResultsTableViewCell.self, forCellReuseIdentifier: "productCell")
		resultsTableView.register(NextTableViewCell.self, forCellReuseIdentifier: "nextPageCell")
		
		title = "Results"
		
		showLoadingSpinnerWith(text: "Loading...")
		
		dataManager.delegate = self
		
		dataManager.loadProducts()
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		if size.width > size.height {
			// landscape
			sortBarTop.constant = 44
		} else {
			// portrait
			sortBarTop.constant = 64
		}
		progressHUD?.reorient()
	}
	
	// MARK: Sort-related methods

	@IBAction func sortButtonWasPressed(_ sender: UIButton) {
		if sortView == nil {
			let encRect = view.frame
			sortEnclosingView = UIView(frame:encRect)
			sortEnclosingView?.backgroundColor = .clear

			let closeButton = UIButton(type:.custom)
			closeButton.backgroundColor = .clear
			closeButton.frame = (sortEnclosingView?.frame)!
			closeButton.addTarget(self, action: #selector(dismissSortView), for: .touchUpInside)
			sortEnclosingView?.addSubview(closeButton)
			
			let buttonRelativeRect = sender.superview?.convert(sender.frame, to:self.view)
			let yOrigin = (buttonRelativeRect?.origin.y)! + (buttonRelativeRect?.size.height)! + 2.0
			sortView = SortView(frame: CGRect(x:view.frame.size.width - 215.0, y:yOrigin, width:200.0, height:176.0))
			sortView?.delegate = self
			sortEnclosingView?.addSubview(sortView!)
		}
		view.addSubview(sortEnclosingView!)
	}

	func dismissSortView() {
		sortEnclosingView?.removeFromSuperview()
	}
	
	// MARK: Loading spinner methods
	
	func showLoadingSpinnerWith(text: String) {
		progressHUD = ProgressHUD(text: text)
		self.view.addSubview(progressHUD!)
		progressHUD?.show()
		resultsTableView.isUserInteractionEnabled = false
		sortButton.isUserInteractionEnabled = false
	}
	
	func hideLoadingSpinner() {
		resultsTableView.isUserInteractionEnabled = true
		sortButton.isUserInteractionEnabled = true
		progressHUD?.hide()
		progressHUD?.removeFromSuperview()
		progressHUD = nil
	}
	
	
	// MARK: UITableViewDataSource methods
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return dataManager.productArray.count > 0 ? 1 : 0
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataManager.productArray.count > 0 ? dataManager.hasMore() ? dataManager.productArray.count + 1 : dataManager.productArray.count : 0
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		if indexPath.row < dataManager.productArray.count {
			let cell = tableView.dequeueReusableCell(withIdentifier: "productCell", for: indexPath) as! SearchResultsTableViewCell
			
			let product = dataManager.productArray[indexPath.row]
			
			if let string = product.productImageURLString, !(product.productImageURLString?.isEmpty)! {
				cell.productImageView?.downloadImageFrom(link: string, contentMode: .scaleAspectFit)
			}

			cell.nameLabel?.text = product.productName
			cell.priceLabel?.text = product.priceString
			cell.ratingLabel?.text = product.userFriendlyRating
			
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "nextPageCell", for: indexPath) as! NextTableViewCell
			cell.indicator.startAnimating()
			cell.statusLabel?.text = "Loading next page..."
			return cell
		}
	}
	
	
	// MARK: UITableViewDelegate methods
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if cell.isKind(of: NextTableViewCell.self) {
			if dataManager.hasMore() {
				// Load next page
				dataManager.loadMoreProducts()
			}
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		self.performSegue(withIdentifier: "product_detail", sender: nil)
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	
	// MARK: Segue Method
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "product_detail" {
			if let pdvc = segue.destination as? ProductDetailViewController {
				if let indexPath = resultsTableView.indexPathForSelectedRow {
					let selectedProduct = dataManager.productArray[indexPath.row]
					pdvc.product = selectedProduct
				}
			}
		}
	}
	
	
	// MARK: DataManagerDelegate methods
	
	func managerHasUpdates() {
		if (progressHUD != nil) {
			// hide spinner
			hideLoadingSpinner()
		}
		
		resultsCountLabel.text = "Top \(dataManager.productArray.count) Results"
		resultsTableView.reloadData()
	}
	
	func retrievalFailedWith(error: String) {
		if retryCount < 2 {
			dataManager.loadProducts()
		} else {
			if alert == nil {
				// show an alert
				let message = "Apologies, a network error has occured: " + error
				alert = UIAlertController(title: "ERROR!", message: message, preferredStyle: .alert)
				alert!.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
				present(alert!, animated: true)
			}
		}
	}

	
	// MARK: SortViewDelegate method
	
	func sortOptionSelected(option: String) {
		dataManager.sortWith(option: option)
		resultsTableView.reloadData()
		dismissSortView()
		resultsTableView.setContentOffset(CGPoint.zero, animated: true)
	}
}


class SearchResultsTableViewCell: UITableViewCell {
	
	var productImageView: UIImageView!
	var nameLabel: UILabel!
	var priceLabel: UILabel!
	var ratingLabel: UILabel!
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		self.accessoryType = .disclosureIndicator
		
		// create productImageView
		productImageView = UIImageView()
		productImageView.contentMode = .scaleAspectFit
		contentView.addSubview(productImageView)
		productImageView.translatesAutoresizingMaskIntoConstraints = false
		productImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
		productImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
		productImageView.heightAnchor.constraint(equalToConstant: 90).isActive = true
		productImageView.widthAnchor.constraint(equalToConstant: 90).isActive = true
		productImageView.image = UIImage(named: "placeholder")
		
		// create nameLabel
		nameLabel = UILabel()
		contentView.addSubview(nameLabel)
		nameLabel.adjustsFontSizeToFitWidth = true
		nameLabel.minimumScaleFactor = 0.5
		nameLabel.numberOfLines = 2
		nameLabel.translatesAutoresizingMaskIntoConstraints = false
		nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
		nameLabel.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: 10).isActive = true
		nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
		nameLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true

		// create priceLabel
		priceLabel = UILabel()
		contentView.addSubview(priceLabel)
		priceLabel.adjustsFontSizeToFitWidth = true
		priceLabel.minimumScaleFactor = 0.5
		priceLabel.font = UIFont.boldSystemFont(ofSize: 20.0)
		priceLabel.translatesAutoresizingMaskIntoConstraints = false
		priceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10).isActive = true
		priceLabel.leadingAnchor.constraint(equalTo: productImageView.trailingAnchor, constant: 10).isActive = true
		priceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true

		// create ratingLabel
		ratingLabel = UILabel()
		contentView.addSubview(ratingLabel)
		ratingLabel.adjustsFontSizeToFitWidth = true
		ratingLabel.minimumScaleFactor = 0.5
		ratingLabel.translatesAutoresizingMaskIntoConstraints = false
		ratingLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10).isActive = true
		ratingLabel.leadingAnchor.constraint(equalTo: priceLabel.trailingAnchor, constant: 10).isActive = true
		ratingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
		ratingLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
		ratingLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}


class NextTableViewCell: UITableViewCell {
	
	var indicator: UIActivityIndicatorView!
	var statusLabel: UILabel!
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		self.accessoryType = .none
		
		// create indicator
		indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
		contentView.addSubview(indicator)
		indicator.translatesAutoresizingMaskIntoConstraints = false
		indicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
		indicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant:70.0).isActive = true
		
		// create statusLabel
		statusLabel = UILabel()
		contentView.addSubview(statusLabel)
		statusLabel.translatesAutoresizingMaskIntoConstraints = false
		statusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
		statusLabel.heightAnchor.constraint(equalToConstant: 30).isActive = true
		statusLabel.leadingAnchor.constraint(equalTo: indicator.trailingAnchor, constant: 10).isActive = true
		statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}

extension UIImageView {
	func downloadImageFrom(link:String, contentMode: UIViewContentMode) {
		URLSession.shared.dataTask( with: NSURL(string:link)! as URL, completionHandler: {
			(data, response, error) -> Void in
			DispatchQueue.main.async {
				self.contentMode =  contentMode
				if let data = data { self.image = UIImage(data: data) }
			}
		}).resume()
	}
}
