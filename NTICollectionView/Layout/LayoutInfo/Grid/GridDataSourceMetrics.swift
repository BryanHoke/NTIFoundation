//
//  GridDataSourceMetrics.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/12/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public struct GridDataSourceSectionMetrics: DataSourceSectionMetricsProviding {
	
	public init() {}
	
	public var metrics: SectionMetrics = GridSectionMetrics()
	
	public var sectionBuilderType: LayoutSectionBuilder.Type = GridLayoutSectionBuilder.self
	
	public var placeholder: AnyObject?
	
	public var placeholderHeight: CGFloat = 200
	
	public var placeholderHasEstimatedHeight: Bool = true
	
	public var placeholderShouldFillAvailableHeight = true
	
	public var supplementaryItemsByKind: [String: [SupplementaryItem]] = [:]
	
	public var sizingInfo: CollectionViewLayoutMeasuring?
	
	public func isEqual(to other: LayoutMetrics) -> Bool {
		guard let other = other as? GridDataSourceSectionMetrics else {
			return false
		}
		
		return metrics.isEqual(to: other.metrics)
	}
	
	public func definesMetric(_ metric: String) -> Bool {
		return false
	}
	
	public mutating func resolveMissingValuesFromTheme() {
		metrics.resolveMissingValuesFromTheme()
	}
	
}

public struct GridLayout : LayoutClass {
	
	public typealias SectionMetricsType = GridSectionMetrics
	
	public typealias SupplementaryItemType = GridSupplementaryItem
	
	public typealias LayoutBuilderType = GridLayoutSectionBuilder
	
}
