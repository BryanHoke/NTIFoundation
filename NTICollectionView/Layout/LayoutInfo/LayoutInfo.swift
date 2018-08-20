//
//  LayoutInfo.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/11/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

public protocol LayoutAttributesResolving {
	
	func layoutAttributesForSupplementaryElementOfKind(_ kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes?
	
	func layoutAttributesForDecorationViewOfKind(_ kind: String, at indexPath: IndexPath) -> CollectionViewLayoutAttributes?
	
	func layoutAttributesForCell(at indexPath: IndexPath) -> CollectionViewLayoutAttributes?
	
}

func invalidateLayoutAttributes(_ attributes: UICollectionViewLayoutAttributes, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
	guard let invalidationContext = invalidationContext else {
		return
	}
	let indexPaths = [attributes.indexPath]
	switch attributes.representedElementCategory {
	case .cell:
		invalidationContext.invalidateItems(at: indexPaths)
	case .decorationView:
		invalidationContext.invalidateDecorationElements(ofKind: attributes.representedElementKind!, at: indexPaths)
	case .supplementaryView:
		invalidationContext.invalidateSupplementaryElements(ofKind: attributes.representedElementKind!, at: indexPaths)
	}
}

/// A type that represents collection view layout information.
public protocol LayoutInfo: LayoutSizing, LayoutAttributesResolving, LayoutSectionProvider {
	
	/// The size of the collection view.
	var collectionViewSize: CGSize { get set }
	
	/// The height of the layout.
	var height: CGFloat { get set }
	
	/// The additional height that's available to placeholders.
	var heightAvailableForPlaceholders: CGFloat { get set }
	
	/// The content offset of the layout.
	var contentOffset: CGPoint { get set }
	
	/// The content inset of the layout.
	var contentInset: UIEdgeInsets { get set }
	
	/// The bounds of the layout.
	var bounds: CGRect { get set }
	
	/// Whether the layout is currently being edited.
	var isEditing: Bool { get set }
	
	/// The layout sections.
	var sections: [LayoutSection] { get }
	
	/// Modifies the section at the specified index using a closure.
	func mutateSection(at index: Int, using mutator: (inout LayoutSection) -> Void)
	
	/// Modifies the item at the specified index path using a closure.
	func mutateItem(at indexPath: IndexPath, using mutator: (inout LayoutItem) -> Void)
	
	/// Create a new placeholder covering the specified range of sections.
	func newPlaceholderStartingAtSectionIndex(_ sectionIndex: Int) -> LayoutPlaceholder
	
	/// Remove all sections including the global section, thus invalidating all layout information.
	func invalidate()
	
	/// Make any necessary preparations before layout begins.
	func prepareForLayout()
	
	/// Finalize the layout. This method adjusts the size of placeholders and calls each section's `finalizeLayoutAttributesForSectionsWithContent(_:)` method.
	func finalizeLayout()
	
	/// Update the size of an item and mark it as invalidated in the given invalidationContext. This is needed for self-sizing view support. This method also adjusts the position of any content affected by the size change.
	func setSize(_ size: CGSize, forItemAt indexPath: IndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	/// Update the size of a supplementary item and mark it as invalidated in the given *invalidationContext*. This is needed for self-sizing view support. This method also adjusts the position of any content affected by the size change.
	func setSize(_ size: CGSize, forElementOfKind kind: String, at indexPath: IndexPath, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
	/// Updates special layout items for a given content offset using
	/// a specific invalidation context.
	func updateSpecialItemsWithContentOffset(_ contentOffset: CGPoint, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
}

public protocol LayoutSectionProvider: class {
	
	var numberOfSections: Int { get }
	
	var hasGlobalSection: Bool { get }
	
	func enumerateSections(_ block: (_ sectionIndex: Int, _ sectionInfo: inout LayoutSection, _ stop: inout Bool) -> Void)
	
	/// Return the layout section with the given sectionIndex.
	func sectionAtIndex(_ sectionIndex: Int) -> LayoutSection?
	
	func setSection(_ section: LayoutSection, at sectionIndex: Int)
	
	func add(_ section: LayoutSection, sectionIndex: Int)
	
}

public protocol LayoutSizing: class {
	
	/// The width of the portion of the layout represented by `self`.
	var width: CGFloat { get set }
	
	var layoutMeasure: CollectionViewLayoutMeasuring? { get }
	
}

open class LayoutSizingInfo: LayoutSizing {
	
	public init(width: CGFloat, layoutMeasure: CollectionViewLayoutMeasuring?) {
		self.width = width
		self.layoutMeasure = layoutMeasure
	}
	
	open var width: CGFloat
	
	open var layoutMeasure: CollectionViewLayoutMeasuring?
	
}

/// A two-dimensional region in a collection view layout.
///
/// An adopting type may represent a single layout element or a composition of layout elements.
public protocol LayoutArea {
	
	var frame: CGRect { get set }
	
	/// Update the frame of `self` and any child areas. 
	///
	/// If the frame has changed, mark objects as invalid in the invalidation context as necessary.
	mutating func setFrame(_ frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?)
	
}


public protocol LayoutElement: LayoutArea {
	
	var itemIndex: Int { get set }
	
	var indexPath: IndexPath { get }
	
	var layoutAttributes: CollectionViewLayoutAttributes { get }
	
	mutating func resetLayoutAttributes()
	
}


/// Layout information about a supplementary item.
public protocol LayoutSupplementaryItem: SupplementaryItemWrapper, LayoutElement {
	
	var sectionIndex: Int { get set }
	
	var supplementaryItem: SupplementaryItem { get set }
	
}

extension LayoutSupplementaryItem {
	
	public var layoutAttributes: CollectionViewLayoutAttributes {
		let attributes = CollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
		
		configureValues(of: attributes)
		
		return attributes
	}
	
}

public protocol LayoutSupplementaryItemWrapper: LayoutSupplementaryItem {
	
	var layoutSupplementaryItem: LayoutSupplementaryItem { get set }
	
}

extension LayoutSupplementaryItemWrapper {
	
	public var frame: CGRect {
		get {
			return layoutSupplementaryItem.frame
		}
		set {
			layoutSupplementaryItem.frame = newValue
		}
	}
	
	public var itemIndex: Int {
		get {
			return layoutSupplementaryItem.itemIndex
		}
		set {
			layoutSupplementaryItem.itemIndex = newValue
		}
	}
	
	public var sectionIndex: Int {
		get {
			return layoutSupplementaryItem.sectionIndex
		}
		set {
			layoutSupplementaryItem.sectionIndex = newValue
		}
	}
	
	public var indexPath: IndexPath {
		return layoutSupplementaryItem.indexPath
	}
	
	public var layoutAttributes: UICollectionViewLayoutAttributes {
		return layoutSupplementaryItem.layoutAttributes
	}
	
	public mutating func resetLayoutAttributes() {
		layoutSupplementaryItem.resetLayoutAttributes()
	}
	
	public mutating func setFrame(_ frame: CGRect, invalidationContext: UICollectionViewLayoutInvalidationContext?) {
		layoutSupplementaryItem.setFrame(frame, invalidationContext: invalidationContext)
	}
	
}
