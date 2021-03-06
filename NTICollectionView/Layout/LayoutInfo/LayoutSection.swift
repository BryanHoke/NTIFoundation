//
//  LayoutSection.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/11/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol LayoutSection: LayoutAttributesResolving {
	
	var frame: CGRect { get set }
	var sectionIndex: Int { get set }
	
	var isGlobalSection: Bool { get }
	
	var items: [LayoutItem] { get }
	var supplementaryItems: [LayoutSupplementaryItem] { get }
	var supplementaryItemsByKind: [String: [LayoutSupplementaryItem]] { get }
	
	var phantomCellIndex: Int? { get set }
	var phantomCellSize: CGSize { get set }
	
	var decorations: [LayoutDecoration] { get }
	
	var placeholderInfo: LayoutPlaceholder? { get set }
	var shouldResizePlaceholder: Bool { get }
	
	func supplementaryItems(of kind: String) -> [LayoutSupplementaryItem]
	mutating func setSupplementaryItems(_ supplementaryItems: [LayoutSupplementaryItem], of kind: String)
	
	/// All the layout attributes associated with this section.
	var layoutAttributes: [CollectionViewLayoutAttributes] { get }
	
	var decorationAttributesByKind: [String: [CollectionViewLayoutAttributes]] { get }
	
	mutating func add(_ supplementaryItem: LayoutSupplementaryItem)
	mutating func add(_ item: LayoutItem)
	mutating func setItem(_ item: LayoutItem, at index: Int)
	
	mutating func mutateItem(at index: Int, using mutator: (inout LayoutItem) -> Void)
	mutating func mutateItems(using mutator: (_ item: inout LayoutItem, _ index: Int) -> Void)
	
	mutating func mutateSupplementaryItems(using mutator: (_ supplementaryItem: inout LayoutSupplementaryItem, _ kind: String, _ index: Int) -> Void)
	
	/// Update the frame of this grouped object and any child objects. Use the invalidation context to mark layout objects as invalid.
	mutating func setFrame(_ frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	/// Reset the content of this section.
	mutating func reset()
	
	func shouldShow(_ supplementaryItem: SupplementaryItem) -> Bool
	
	mutating func finalizeLayoutAttributesForSectionsWithContent(_ sectionsWithContent: [LayoutSection])
	
	mutating func setSize(_ size: CGSize, forItemAt index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
	mutating func setSize(_ size: CGSize, forSupplementaryElementOfKind kind: String, at index: Int, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
	func additionalLayoutAttributesToInsertForInsertionOfItem(at indexPath: IndexPath) -> [CollectionViewLayoutAttributes]
	
	func additionalLayoutAttributesToDeleteForDeletionOfItem(at indexPath: IndexPath) -> [CollectionViewLayoutAttributes]
	
	mutating func prepareForLayout()
	
	func targetLayoutHeightForProposedLayoutHeight(_ proposedHeight: CGFloat, layoutInfo: LayoutInfo) -> CGFloat
	
	func targetContentOffsetForProposedContentOffset(_ proposedContentOffset: CGPoint, firstInsertedSectionMinY: CGFloat) -> CGPoint
	
	mutating func updateSpecialItemsWithContentOffset(_ contentOffset: CGPoint, layoutInfo: LayoutInfo, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	mutating func applyValues(from metrics: LayoutMetrics)
	
	func isEqual(to other: LayoutSection) -> Bool
	
}

extension LayoutSection {
	
	public var numberOfItems: Int {
		return items.count
	}
	
	public var layoutAttributes: [CollectionViewLayoutAttributes] {
		var layoutAttributes: [CollectionViewLayoutAttributes] = []
		
		layoutAttributes += items.map {$0.layoutAttributes}
		
		layoutAttributes += supplementaryItems.map {$0.layoutAttributes}
		
		layoutAttributes += decorations.map {$0.layoutAttributes}
		
		if let placeholderInfo = self.placeholderInfo, placeholderInfo.startingSectionIndex == sectionIndex {
			layoutAttributes.append(placeholderInfo.layoutAttributes)
		}
		
		return layoutAttributes
	}
	
	public var isGlobalSection: Bool {
		return sectionIndex == globalSectionIndex
	}
	
}

public protocol LayoutEngine {
	
	/// Layout this section with the given starting origin and using the invalidation context to record cells and supplementary views that should be redrawn.
	func layoutWithOrigin(_ origin: CGPoint, layoutSizing: LayoutSizing, invalidationContext: UICollectionViewLayoutInvalidationContext?) -> CGPoint
	
}

public func layoutSection(_ self: inout LayoutSection, setFrame frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
	guard frame != self.frame else {
		return
	}
	let offset = CGPoint(x: frame.origin.x - self.frame.origin.x, y: frame.origin.y - self.frame.origin.y)
	
	self.mutateSupplementaryItems { (supplementaryItem, _, _) in
		let supplementaryFrame = supplementaryItem.frame.offsetBy(dx: offset.x, dy: offset.y)
		supplementaryItem.setFrame(supplementaryFrame, invalidationContext: invalidationContext)
	}
	
	self.frame = frame
}

public func layoutSection(_ self: inout LayoutSection, offsetContentAfter origin: CGPoint, with offset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext? = nil) {
	self.mutateSupplementaryItems { (supplementaryItem, _, _) in
		var supplementaryFrame = supplementaryItem.frame
		if supplementaryFrame.minX < origin.x || supplementaryFrame.minY < origin.y {
			return
		}
		supplementaryFrame = supplementaryFrame.offsetBy(dx: offset.x, dy: offset.y)
		supplementaryItem.setFrame(supplementaryFrame, invalidationContext: invalidationContext)
	}
	
	self.mutateItems { (item, _) in
		var itemFrame = item.frame
		if itemFrame.minX < origin.x || itemFrame.minY < origin.y {
			return
		}
		itemFrame = itemFrame.offsetBy(dx: offset.x, dy: offset.y)
		item.setFrame(itemFrame, invalidationContext: invalidationContext)
	}
}
