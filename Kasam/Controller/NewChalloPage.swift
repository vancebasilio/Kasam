//
//  NewKasamPageController.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-12-23.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit

class NewChalloPageController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    var pageControl = UIPageControl()
    lazy var orderedViewControllers: [UIViewController] = {
        return [self.newVc(viewController: "NewChallo"), self.newVc(viewController: "NewBlock") ,self.newVc(viewController: "ChalloHolder")]
    }()
    
    var currentIndex:Int {
        get {return orderedViewControllers.index(of: self.viewControllers!.first!)!}
        set {
            guard newValue >= 0,newValue < orderedViewControllers.count else {return}
            let vc = orderedViewControllers[newValue]
            let direction:UIPageViewController.NavigationDirection = newValue > currentIndex ? .forward : .reverse
            self.setViewControllers([vc], direction: direction, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        self.dataSource = self
        self.delegate = self
        
        for view in self.view.subviews {
           if let scrollView = view as? UIScrollView {
              scrollView.delegate = self
           }
        }
        
        // This sets up the first view that will show up on our page control
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
        if let thirdViewController = orderedViewControllers.last as? ChalloHolder {
            thirdViewController.reviewOnly = true
        }
        //customize action of back button
        let newBackButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(NewChalloPageController.back(sender:)))
        newBackButton.image = UIImage(named: "back-button")
        self.navigationItem.leftBarButtonItem = newBackButton
        
        //next button
        let goToNext = NSNotification.Name("GoToNext")
        NotificationCenter.default.addObserver(self, selector: #selector(NewChalloPageController.goToNext), name: goToNext, object: nil)
        
        configurePageControl()
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @objc func back(sender: UIBarButtonItem) {
        if self.pageControl.currentPage == 0 {
            _ = navigationController?.popToRootViewController(animated: true)
        } else if self.pageControl.currentPage == 1 {
             if let firstViewController = orderedViewControllers.first {
                setViewControllers([firstViewController], direction: .reverse, animated: true, completion: nil)
                self.pageControl.currentPage = self.currentIndex
            }
        } else if self.pageControl.currentPage == 2 {
            if let secondViewController = orderedViewControllers[1] as? NewBlockController {
                setViewControllers([secondViewController], direction: .reverse, animated: true, completion: nil)
                self.pageControl.currentPage = self.currentIndex
            }
        }
    }
    
    @objc func goToNext(){
        goToNextPage(animated: true) {(true) in
            self.pageControl.currentPage = self.currentIndex
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
        
        if (!completed)
        {
          return
        }
        self.pageControl.currentPage = pageViewController.viewControllers!.first!.view.tag //Page Index
    }
    
    //BEFORE FIRST CONTROLLER
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    //AFTER LAST VIEW CONTROLLER
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
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

extension NewChalloPageController: UIScrollViewDelegate {
    //prevents users from pulling views past the last controller (which shows up black)
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.bounces = false
    }
}
