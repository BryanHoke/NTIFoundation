//
//  GridLayoutSectionBuilder.swift
//  NTIFoundation
//
//  Created by Bryan Hoke on 4/19/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct GridLayoutSectionBuilder: LayoutSectionBuilder {
	
	public init?(metrics: SectionMetrics) {
		guard let gridMetrics = metrics as? GridSectionMetricsProviding else {
			return nil
		}
		
		self.metrics = gridMetrics
	}
	
	public let metrics: GridSectionMetricsProviding
	
	public func makeLayoutSection(using description: SectionDescription, in layoutBounds: LayoutAreaBounds) -> LayoutSection {
		let section = BasicGridLayoutSection()
		
		// TODO: Implement
		
		return section
	}
	
}
