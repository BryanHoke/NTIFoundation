//
//  CatDetailViewController.swift
//  AdvancedCollectionViewDemo
//
//  Created by Bryan Hoke on 2/27/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import NTICollectionView

class CatDetailViewController: CollectionViewController {
	
	init(cat: AAPLCat) {
		self.cat = cat
		super.init(collectionViewLayout: CollectionViewLayout())
	}

	required init?(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
	}
	
	var cat: AAPLCat!
	
	private var dataSource = SegmentedCollectionDataSource()
	private var detailDataSource: CatDetailDataSource!
	private var sightingDataSource: CatSightingsDataSource!
	private var selectedDataSourceObserver: AnyObject?

    override func viewDidLoad() {
        super.viewDidLoad()

		dataSource.defaultMetrics = GridDataSourceSectionMetrics()
		detailDataSource = newDetailDataSource()
		sightingDataSource = newSightingsDataSource()
		
		dataSource.add(detailDataSource)
		dataSource.add(sightingDataSource)
		
		let globalHeader = BasicGridSupplementaryItem(elementKind: UICollectionElementKindSectionHeader)
		dataSource.add(globalHeader, forKey: "globalHeader")
		globalHeader.isVisibleWhileShowingPlaceholder = true
		globalHeader.estimatedHeight = 110
		globalHeader.supplementaryViewClass = AAPLCatDetailHeader.self
		globalHeader.configure { [unowned self] (view, dataSource, indexPath) -> Void in
			guard let headerView = view as? AAPLCatDetailHeader else {
				return
			}
			headerView.configureWithCat(self.cat)
		}
		
		let segmentedHeader = GridSegmentedControlHeader()
		segmentedHeader.supplementaryViewClass = AAPLSegmentedHeaderView.self
		segmentedHeader.showsSeparator = true
		segmentedHeader.configure { (view, dataSource, indexPath) in
			guard let dataSource = dataSource as? SegmentedCollectionDataSource,
				headerView = view as? AAPLSegmentedHeaderView else {
					return
			}
			let segmentedControl = headerView.segmentedControl
			segmentedHeader.segmentedControl = segmentedControl
			dataSource.configure(segmentedControl)
		}
		dataSource.segmentedControlHeader = segmentedHeader
		
		collectionView?.dataSource = dataSource
    }

	private func newDetailDataSource() -> CatDetailDataSource {
		let dataSource = CatDetailDataSource(cat: cat)
		dataSource.title = "Details"
		
		dataSource.noContentPlaceholder = BasicDataSourcePlaceholder(title: "No Cat", message: "This cat has no information.", image: nil)
		
		dataSource.defaultMetrics = GridDataSourceSectionMetrics()
		
		return dataSource
	}
	
	private func newSightingsDataSource() -> CatSightingsDataSource {
		let dataSource = CatSightingsDataSource(cat: cat)
		dataSource.title = "Sightings"
		
		dataSource.noContentPlaceholder = BasicDataSourcePlaceholder(title: "No Sightings", message: "This cat has not been sighted recently.", image: nil)
		
		let metrics = GridDataSourceSectionMetrics()
		if let gridMetrics = metrics.metrics as? GridSectionMetrics {
			gridMetrics.showsRowSeparator = true
			gridMetrics.separatorInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
			gridMetrics.estimatedRowHeight = 60
		}
		dataSource.defaultMetrics = metrics
		
		return dataSource
	}

}