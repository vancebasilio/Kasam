//
//  DiscoverKasamCell.swift
//  Kasam
//
//  Created by Vance Basilio on 2020-02-15.
//  Copyright © 2020 Vance Basilio. All rights reserved.
//

import UIKit

class DiscoverKasamCell: UITableViewCell {
    
    @IBOutlet private weak var discoverCollectionView: UICollectionView!
    @IBOutlet weak var DiscoverCategoryTitle: UILabel!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setCollectionViewDataSourceDelegate(dataSourceDelegate: UICollectionViewDataSource & UICollectionViewDelegate, forRow row: Int) {
        discoverCollectionView.delegate = dataSourceDelegate
        discoverCollectionView.dataSource = dataSourceDelegate
        discoverCollectionView.tag = row
        discoverCollectionView.reloadData()
    }
    
    func disableSwiping(){discoverCollectionView.isScrollEnabled = false}
    func enableSwiping(){discoverCollectionView.isScrollEnabled = true}

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
