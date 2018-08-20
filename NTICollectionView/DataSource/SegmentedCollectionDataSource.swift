//
//  SegmentedCollectionDataSource.swift
//  NTICollectionView
//
//  Created by Bryan Hoke on 2/24/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import UIKit

/// A `ParentCollectionDataSource` that displays only one of its children at a
/// time.
public protocol SegmentedCollectionDataSourceProtocol: ParentCollectionDataSource {
	
	/// The currently selected data source.
	var selectedDataSource: CollectionDataSource? { get set }
	
	/// The child-index of the currently selected data source.
	var selectedDataSourceIndex: Int? { get set }
	
	/// Removes all child data sources from this data source.
	func removeAllDataSources()
	
}

private let segmentedDataSourceHeaderKey = "SegmentedDataSourceHeaderKey"

/** A `CollectionDataSource` with multiple child data sources but only one
	visible data source at a time.

	Only the selected data source will become active. When a new data source is
	selected, the previously selected data source will receive a `willResignActive`
	call before the new data source receives a `didBecomeActive` call.
*/
open class SegmentedCollectionDataSource: CollectionDataSource, CollectionDataSourceDelegate, SegmentedControlDelegate {
	
	/// The collection of data sources contained within this segmented data source.
	open fileprivate(set) var dataSources: [CollectionDataSource] = []
	
	/// Whether changing the selected data source should be animated by default.
	open var animatesSegmentChanges = true
	
	/// Adds a data source to the end of the collection.
	///
	/// The title property of `dataSource` will be used to populate a new segment
	/// in the `UISegmentedControl` associated with this data source.
	open func add(_ dataSource: CollectionDataSource) {
		if dataSources.isEmpty {
			_selectedDataSource = dataSource
		}
		dataSources.append(dataSource)
		dataSource.delegate = self
		notifyDidAddChild(dataSource)
	}
	
	/// Removes the data source from the collection.
	open func remove(_ dataSource: CollectionDataSource) {
		guard let index = dataSourcesIndexOf(dataSource) else {
			return
		}
		dataSources.remove(at: index)
		if dataSource.delegate === self {
			dataSource.delegate = nil
		}
	}
	
	/// Removes all data sources from the collection.
	open func removeAllDataSources() {
		for dataSource in dataSources where dataSource.delegate === self {
			dataSource.delegate = nil
		}
		dataSources = []
		_selectedDataSource = nil
	}
	
	fileprivate func dataSourcesIndexOf(_ dataSource: CollectionDataSource) -> Int? {
		return dataSources.index(where: { $0 === dataSource })
	}
	
	fileprivate func dataSourcesContains(_ dataSource: CollectionDataSource) -> Bool {
		return dataSources.contains(where: { $0 === selectedDataSource })
	}
	
	/// A reference to the currently selected data source.
	///
	/// This property is `nil` until the first data source is added.
	open var selectedDataSource: CollectionDataSource? {
		get {
			return _selectedDataSource
		}
		set {
			setSelectedDataSource(newValue, isAnimated: false)
		}
	}
	fileprivate var _selectedDataSource: CollectionDataSource? {
		didSet {
			segmentedCollectionDataSourceDelegate?.segmentedCollectionDataSourceDidChangeSelectedDataSource(self)
		}
	}
	
	/// An object that receives notice of changes to the selected data source.
	open weak var segmentedCollectionDataSourceDelegate: SegmentedCollectionDataSourceDelegate?
	
	/// Sets the selected data source with optional animation.
	open func setSelectedDataSource(_ selectedDataSource: CollectionDataSource?, isAnimated: Bool) {
		setSelectedDataSource(selectedDataSource, isAnimated: isAnimated, completionHandler: nil)
	}
	
	/// Sets the selected data source with optional animation and invokes an
	/// optional closure afterward.
	open func setSelectedDataSource(_ selectedDataSource: CollectionDataSource?, isAnimated: Bool, completionHandler: (()->())?) {
		guard selectedDataSource !== self.selectedDataSource else {
			completionHandler?()
			return
		}
		if selectedDataSource != nil {
			precondition(dataSourcesContains(selectedDataSource!), "Selected data source must be contained in this data source")
		}
		
		let oldDataSource = self.selectedDataSource
		
		var direction: SectionOperationDirection?
		if isAnimated,
			let oldSelectedDataSource = oldDataSource,
			let newSelectedDataSource = selectedDataSource {
			let oldIndex = dataSourcesIndexOf(oldSelectedDataSource)!
			let newIndex = dataSourcesIndexOf(newSelectedDataSource)!
			direction = (oldIndex < newIndex) ? .Right : .Left
		}
		
		let numberOfOldSections = oldDataSource?.numberOfSections ?? 0
		let numberOfNewSections = selectedDataSource?.numberOfSections ?? 0
		let removedSet = IndexSet(integersIn: NSMakeRange(0, numberOfOldSections).toRange()!)
		let insertedSet = IndexSet(integersIn: NSMakeRange(0, numberOfNewSections).toRange()!)
		
		performUpdate({
			oldDataSource?.willResignActive()
			
			if removedSet.count > 0 {
				self.notifySectionsRemoved(removedSet, direction: direction)
			}
			
			self.willChangeValue(forKey: "selectedDataSource")
			self.willChangeValue(forKey: "selectedDataSourceIndex")
			
			self._selectedDataSource = selectedDataSource
			
			self.didChangeValue(forKey: "selectedDataSource")
			self.didChangeValue(forKey: "selectedDataSourceIndex")
			
			self.segmentedCollectionDataSourceDelegate?.segmentedCollectionDataSourceDidChangeSelectedDataSource(self)
			
			if insertedSet.count > 0 {
				self.notifySectionsInserted(insertedSet, direction: direction)
			}
			
			selectedDataSource?.didBecomeActive()
			}, complete: completionHandler)
	}
	
	/// The index of the selected data source in the collection.
	open var selectedDataSourceIndex: Int? {
		get {
			guard let selectedDataSource = self.selectedDataSource else {
				return nil
			}
			return dataSourcesIndexOf(selectedDataSource)!
		}
		set {
			setSelectedDataSourceIndex(newValue, isAnimated: false)
		}
	}
	
	/// Sets the index of the selected data source with optional animation.
	open func setSelectedDataSourceIndex(_ selectedDataSourceIndex: Int?, isAnimated: Bool) {
		guard let index = selectedDataSourceIndex else {
			selectedDataSource = nil
			return
		}
		let dataSource = dataSources[index]
		selectedDataSource = dataSource
	}
	
	fileprivate func dataSourceAtIndex(_ dataSourceIndex: Int) -> CollectionDataSource {
		return dataSources[dataSourceIndex]
	}
	
	/// The number of sections in the selected data source.
	open override var numberOfSections: Int {
		return selectedDataSource?.numberOfSections ?? 0
	}
	
	open override func dataSourceForSectionAtIndex(_ sectionIndex: Int) -> CollectionDataSource {
		return selectedDataSource?.dataSourceForSectionAtIndex(sectionIndex) ?? super.dataSourceForSectionAtIndex(sectionIndex)
	}
	
	open override func localIndexPathForGlobal(_ globalIndexPath: IndexPath) -> IndexPath? {
		return selectedDataSource?.localIndexPathForGlobal(globalIndexPath)
	}
	
	open override func item(at indexPath: IndexPath) -> AnyItem? {
		return selectedDataSource?.item(at: indexPath)
	}
	
	open override func indexPath(for item: AnyItem) -> IndexPath? {
		return selectedDataSource?.indexPath(for: item) as IndexPath?
	}
	
	open override func removeItem(at indexPath: IndexPath) {
		selectedDataSource?.removeItem(at: indexPath)
	}
	
	open override func registerReusableViews(with collectionView: UICollectionView) {
		super.registerReusableViews(with: collectionView)
		for dataSource in dataSources {
			dataSource.registerReusableViews(with: collectionView)
		}
	}
	
	// TODO: Action stuff?
	
	open override func didBecomeActive() {
		super.didBecomeActive()
		selectedDataSource?.didBecomeActive()
	}
	
	open override func willResignActive() {
		super.willResignActive()
		selectedDataSource?.willResignActive()
	}
	
	open override var allowsSelection: Bool {
		return selectedDataSource?.allowsSelection ?? super.allowsSelection
	}
	
	// TODO: Make computed property for item-by-key?
	/// The supplementary item which contains the segmented control associated
	/// with this data source.
	open var segmentedControlHeader: SegmentedControlSupplementaryItem? {
		didSet {
			guard let segmentedControlHeader = self.segmentedControlHeader else {
				return removeSupplementaryItemForKey(segmentedDataSourceHeaderKey)
			}
			
			guard let oldValue = oldValue else {
				return add(segmentedControlHeader, forKey: segmentedDataSourceHeaderKey)
			}
			
			guard !segmentedControlHeader.isEqual(to: oldValue) else {
				return
			}
			
			replaceSupplementaryItemForKey(segmentedDataSourceHeaderKey, with: segmentedControlHeader)
			configureSegmentedControlHeader()
		}
	}
	
	fileprivate func configureSegmentedControlHeader() {
		guard segmentedControlHeader != nil else {
			return
		}
		
		segmentedControlHeader?.isVisibleWhileShowingPlaceholder = true
		segmentedControlHeader?.shouldPin = true
		
		segmentedControlHeader?.configure { [weak self] (view, dataSource, indexPath) -> Void in
			guard let `self` = self else {
				return
			}
			guard let segmentedDataSource = dataSource as? SegmentedCollectionDataSource else {
				return
			}
			guard let segmentedControl = self.segmentedControlHeader?.segmentedControl else {
				return
			}
			
			segmentedDataSource.configure(segmentedControl)
		}
	}
	
	/// Configures a segmented control to become associated with this data source.
	open func configure(_ segmentedControl: SegmentedControlProtocol) {
		let titles = dataSources.map { $0.title ?? "" }
		
		segmentedControl.setSegments(with: titles, animated: false)
		
		segmentedControl.segmentedControlDelegate = self
		segmentedControl.selectedSegmentIndex = selectedDataSourceIndex ?? UISegmentedControlNoSegment
	}
	
	// MARK: - Metrics
	
	open override var metricsHelper: CollectionDataSourceMetrics {
		return SegmentedCollectionDataSourceMetricsHelper(segmentedDataSource: self)
	}
	
	// MARK: - Subclass hooks
	
	open override func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
		return selectedDataSource?.collectionView(collectionView, canEditItemAt: indexPath) ?? super.collectionView(collectionView, canEditItemAt: indexPath)
	}
	
	open override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
		return selectedDataSource?.collectionView(collectionView, canMoveItemAt: indexPath) ?? super.collectionView(collectionView, canMoveItemAt: indexPath)
	}
	
	// MARK: - ContentLoading
	
	open override func beginLoadingContent(with progress: LoadingProgress) {
		selectedDataSource?.loadContent()
		super.beginLoadingContent(with: progress)
	}
	
	open override func resetContent() {
		for dataSource in dataSources {
			dataSource.resetContent()
		}
		super.resetContent()
	}
	
	// MARK: - Placeholders
	
	open override func update(_ placeholderView: CollectionPlaceholderView?, forSectionAtIndex sectionIndex: Int) {
		selectedDataSource?.update(placeholderView, forSectionAtIndex: sectionIndex)
	}
	
	// MARK: - SegmentedControlDelegate
	
	open func segmentedControlDidChangeValue(_ segmentedControl: SegmentedControlProtocol) {
		segmentedControl.userInteractionEnabled = false
		let selectedSegmentIndex = segmentedControl.selectedSegmentIndex
		// FIXME: fatal error: Index out of range
		// `segmentedControl` does not have a "Members" segment
		let dataSource = dataSources[selectedSegmentIndex]
		setSelectedDataSource(dataSource, isAnimated: animatesSegmentChanges) {
			segmentedControl.userInteractionEnabled = true
		}
	}
	
	// MARK: - UICollectionViewDataSource
	
	open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return shouldShowPlaceholder ? 0 : selectedDataSource?.collectionView(collectionView, numberOfItemsInSection: section) ?? super.collectionView(collectionView, numberOfItemsInSection: section)
	}
	
	open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		return selectedDataSource?.collectionView(collectionView, cellForItemAt: indexPath) ?? super.collectionView(collectionView, cellForItemAt: indexPath)
	}
	
	open override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath, to destinationIndexPath: IndexPath) -> Bool {
		return selectedDataSource?.collectionView(collectionView, canMoveItemAt: indexPath, to: destinationIndexPath) ?? super.collectionView(collectionView, canMoveItemAt: indexPath, to: destinationIndexPath)
	}
	
	open override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		selectedDataSource?.collectionView(collectionView, moveItemAt: sourceIndexPath, to: destinationIndexPath)
	}
	
	// MARK: - CollectionDataSourceDelegate
	
	open func dataSource(_ dataSource: CollectionDataSource, didInsertItemsAt indexPaths: [IndexPath]) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifyItemsInserted(at: indexPaths)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didRemoveItemsAt indexPaths: [IndexPath]) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifyItemsRemoved(at: indexPaths)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didRefreshItemsAt indexPaths: [IndexPath]) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifyItemsRefreshed(at: indexPaths)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didMoveItemAt oldIndexPath: IndexPath, to newIndexPath: IndexPath) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifyItemMoved(from: oldIndexPath, to: newIndexPath)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didInsertSections sections: IndexSet, direction: SectionOperationDirection?) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifySectionsInserted(sections, direction: direction)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didRemoveSections sections: IndexSet, direction: SectionOperationDirection?) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifySectionsRemoved(sections, direction: direction)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didRefreshSections sections: IndexSet) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifySectionsRefreshed(sections)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didMoveSectionFrom oldSection: Int, to newSection: Int, direction: SectionOperationDirection?) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifySectionsMoved(from: oldSection, to: newSection, direction: direction)
	}
	
	open func dataSourceDidReloadData(_ dataSource: CollectionDataSource) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifyDidReloadData()
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, performBatchUpdate update: @escaping () -> Void, complete: (() -> Void)?) {
		guard dataSource === selectedDataSource else {
			update()
			complete?()
			return
		}
		performUpdate(update, complete: complete)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didPresentActivityIndicatorForSections sections: IndexSet) {
		guard dataSource === selectedDataSource else {
			return
		}
		presentActivityIndicator(forSections: sections)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didPresentPlaceholderForSections sections: IndexSet) {
		guard dataSource === selectedDataSource else {
			return
		}
		present(nil, forSections: sections)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didDismissPlaceholderForSections sections: IndexSet) {
		guard dataSource === selectedDataSource else {
			return
		}
		dismissPlaceholder(forSections: sections)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, didUpdate supplementaryItem: SupplementaryItem, at indexPaths: [IndexPath]) {
		guard dataSource === selectedDataSource else {
			return
		}
		notifyContentUpdated(for: supplementaryItem, at: indexPaths)
	}
	
	open func dataSource(_ dataSource: CollectionDataSource, perform update: @escaping (UICollectionView) -> Void) {
		delegate?.dataSource(dataSource, perform: update)
	}
	
}

/// An object which can repond to changes to a `SegmentedCollectionDataSource`.
public protocol SegmentedCollectionDataSourceDelegate: class {
	
	/// Invoked after the delegating data source changes its selected data source.
	func segmentedCollectionDataSourceDidChangeSelectedDataSource(_ segmentedCollectionDataSource: SegmentedCollectionDataSource)
	
}

