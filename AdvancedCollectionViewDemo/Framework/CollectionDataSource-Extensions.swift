//
//  CollectionDataSource-Extensions.swift
//  AdvancedCollectionViewDemo
//
//  Created by Bryan Hoke on 2/26/16.
//  Copyright © 2016 NextThought. All rights reserved.
//

import NTICollectionView

let DataSourceTitleHeaderKey = "DataSourceTitleHeaderKey"

extension AbstractCollectionDataSource {
	
	func makeDataSourceTitleHeader() -> SupplementaryItem {
		return makeSourceHeaderWithTitle(title ?? "NULL")
	}
	
	func makeSourceHeaderWithTitle(title: String) -> SupplementaryItem {
		var header = GridSupplementaryItem(elementKind: UICollectionElementKindSectionHeader)
		header.supplementaryViewClass = AAPLSectionHeaderView.self
		header.configure { (view, dataSource, indexPath) in
			guard let view = view as? AAPLSectionHeaderView else {
				return
			}
			view.leftText = title
		}
		return header
	}
	
}