//
//  BasicHeaderView.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 6/2/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A simple header view that displays a single title label.
public class BasicHeaderView: PinnableHeaderView {

	/// Displays the title text.
    public let titleLabel = UILabel()
	
	public override init(frame: CGRect) {
		super.init(frame: frame)
		
		commonInit()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func commonInit() {
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		addSubview(titleLabel)
		
		let views = ["title": titleLabel]
		var constraints = [NSLayoutConstraint]()
		
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("H:|-[title]-|", options: [], metrics: nil, views: views)
		constraints += NSLayoutConstraint.constraintsWithVisualFormat("V:|-[title]-|", options: [], metrics: nil, views: views)
		
		NSLayoutConstraint.activateConstraints(constraints)
	}

}
