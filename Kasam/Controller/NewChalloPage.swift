//
//  NewKasamPageController.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-12-23.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import Foundation

class NewChalloPageController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    var pageControl = UIPageControl()
    lazy var orderedViewControllers: [UIViewController] = {
        return [self.newVc(viewController: "NewChallo"),
                self.newVc(viewController: "NewBlock")]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        self.dataSource = self
        self.delegate = self
        
        // This sets up the first view that will show up on our page control
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
        //customize action of back button
        let newBackButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(NewChalloPageController.back(sender:)))
        newBackButton.image = UIImage(named: "back-button")
        self.navigationItem.leftBarButtonItem = newBackButton
        configurePageControl()
    }
    
    @objc func back(sender: UIBarButtonItem) {
        if self.pageControl.currentPage == 0 {
            _ = navigationController?.popToRootViewController(animated: true)
        } else {
             if let firstViewController = orderedViewControllers.first {
                setViewControllers([firstViewController], direction: .reverse, animated: true, completion: nil)
            }
        }
    }

    func configurePageControl() {
        pageControl = UIPageControl(frame: CGRect(x: 0,y: UIScreen.main.bounds.maxY - 50,width: UIScreen.main.bounds.width,height: 50))
        self.pageControl.numberOfPages = orderedViewControllers.count
        self.pageControl.currentPage = 0
        self.pageControl.tintColor = UIColor.black
        self.pageControl.pageIndicatorTintColor = UIColor.lightGray
        self.pageControl.currentPageIndicatorTintColor = UIColor.black
        self.pageControl.backgroundColor = UIColor.white
        self.pageControl.isUserInteractionEnabled = false
        self.view.addSubview(pageControl)
    }
    
    func newVc(viewController: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: viewController)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
        self.pageControl.currentPage = orderedViewControllers.index(of: pageContentViewController)!
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.colorFour
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        return orderedViewControllers[nextIndex]
    }
}
