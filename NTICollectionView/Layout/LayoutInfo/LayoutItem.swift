//
//  LayoutItem.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/17/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import Foundation
import UIKit

/// Layout information about an item (cell).
public protocol LayoutItem: LayoutElement, LayoutMetricsApplicable {
	
	var columnIndex: Int { get set }
	
	var hasEstimatedHeight: Bool { get set }
	
	var isDragging: Bool { get set }
	
	var sectionIndex: Int { get set }
	
	func isEqual(to other: LayoutItem) -> Bool
	
}
