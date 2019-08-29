//
//  KasamDeetsHolder.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-07-01.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit
import MXSegmentedPager
import Firebase

class KasamDeetsHolder: MXSegmentedPagerController {
    
    var kasamID: String = ""    //transfered in values from previous vc
    var kasamGTitle: String = "" //transfered in values from previous vc
    var position = CGFloat(2.0)
    
    @IBOutlet var holderView: UIView!
    @IBOutlet var headerView: UIView!
    @IBOutlet weak var kasamImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupStretchyHeader()
        setupNavBar()
        getKasamData()
    }
    
    func setupNavBar(){
        if let navBar = self.navigationController?.navigationBar {
            extendedLayoutIncludesOpaqueBars = true
            navBar.isTranslucent = true
            navBar.backgroundColor = UIColor.clear
            navBar.setBackgroundImage(UIImage(), for: .default)
            navBar.shadowImage = UIImage() //remove bottom border on navigation bar
            navBar.tintColor = UIColor.white //change back arrow to white
        }
    }
    
    func setupStretchyHeader() {
        // Parallax Header
        let newView = headerView
        segmentedPager.parallaxHeader.view = headerView
        segmentedPager.parallaxHeader.mode = .fill
        segmentedPager.parallaxHeader.height = 200
        segmentedPager.parallaxHeader.minimumHeight = 0
        
        let margins = view.layoutMarginsGuide
        newView?.topAnchor.constraint(equalTo: margins.topAnchor, constant: -64).isActive = true
        
        // Segmented Control customization
        segmentedPager.segmentedControl.selectionIndicatorLocation = .down
        segmentedPager.segmentedControl.isHidden = true
        segmentedPager.segmentedControlPosition = .top
        segmentedPager.segmentedControl.backgroundColor = .clear
        segmentedPager.backgroundColor = .clear
        segmentedPager.pager.backgroundColor = .clear
        segmentedPager.pager.layer.cornerRadius = 20.0
        segmentedPager.pager.clipsToBounds = true
    }
    
    override func heightForSegmentedControl(in segmentedPager: MXSegmentedPager?) -> CGFloat {
        return 0
    }
    
    override func segmentedPager(_ segmentedPager: MXSegmentedPager, didScrollWith parallaxHeader: MXParallaxHeader) {
        position = 2.0 - parallaxHeader.progress
        segmentedPager.segmentedControl.contentScaleFactor = position
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            let kasamTransferHolder = segue.destination as! KasamDeetsViewController
            kasamTransferHolder.kasamID = kasamID
            kasamTransferHolder.kasamGTitle = kasamGTitle
    }

    //Retrieves Kasam header image
    func getKasamData(){
        Database.database().reference().child("Coach-Kasams").child(kasamID).observe(.value, with: { (snapshot) in
            if let value = snapshot.value as? [String: Any] {
                let headerURL = URL(string: value["Image"] as? String ?? "")
                self.kasamImage.image = UIImage(named: "placeholder.png")?.resizeTopAlignedToFill(newWidth: self.kasamImage.frame.width)
                self.kasamImage.sd_setImage(with: headerURL, placeholderImage: UIImage(named: "placeholder.png"))
            }
        })
    }
}
