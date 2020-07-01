//
//  NewKasamPageController.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-12-23.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit

class NewKasamPageController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    var pageControl = UIPageControl()
    var kasamType = ""
    lazy var orderedViewControllers: [UIViewController] = {
        let firstVC = self.newVc(viewController: "NewKasam") as! NewKasamController
        firstVC.basicKasam = true
        return [firstVC]
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
    
    override func viewWillAppear(_ animated: Bool){
        self.tabBarController?.tabBar.isHidden = true
        self.tabBarController?.tabBar.isTranslucent = true
        UIView.transition(with: tabBarController!.view, duration: 0.35, options: .transitionCrossDissolve, animations: nil)
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.backgroundColor = UIColor.white.withAlphaComponent(0)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()         //remove bottom border on navigation bar
        self.navigationController?.navigationBar.tintColor = UIColor.white       //makes the back button white
        for subview in self.navigationController!.navigationBar.subviews {
            if subview.restorationIdentifier == "rightButton" {subview.isHidden = true}
        }
        self.navigationItem.backBarButtonItem?.title = ""
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
        self.tabBarController?.tabBar.isTranslucent = false
        self.navigationController?.navigationBar.isTranslucent = false
        for subview in self.navigationController!.navigationBar.subviews {
            if subview.restorationIdentifier == "rightButton" {subview.isHidden = false}
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        
        for view in self.view.subviews {
           if let scrollView = view as? UIScrollView {
              scrollView.delegate = self
           }
        }
        if kasamType == "complex" {
            orderedViewControllers = [self.newVc(viewController: "NewKasam"), self.newVc(viewController: "NewBlock") ,self.newVc(viewController: "KasamHolder")]
        }
        configurePageControl()
        
        // This sets up the first view that will show up on our page control
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
        if let thirdViewController = orderedViewControllers.last as? KasamHolder {
            thirdViewController.reviewOnly = true
        }
        //customize action of back button
        let newBackButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(NewKasamPageController.back(sender:)))
        newBackButton.image = UIImage(named: "back-button")
        self.navigationItem.leftBarButtonItem = newBackButton
        
        //next button
        let goToNext = NSNotification.Name("GoToNext")
        NotificationCenter.default.addObserver(self, selector: #selector(NewKasamPageController.goToNext), name: goToNext, object: nil)
        
        //back button
        let goToBack = NSNotification.Name("GoToBack")
        NotificationCenter.default.addObserver(self, selector: #selector(NewKasamPageController.back(sender:)), name: goToBack, object: nil)
    }
    
    @objc func back(sender: UIBarButtonItem) {
        if kasamType == "complex" {
            if self.pageControl.currentPage == 0 {
                navigationController?.popToRootViewController(animated: true)
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
        } else {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "BackButtonBasicKasam"), object: self)
        }
    }
    
    @objc func goToNext(){
        goToNextPage(animated: true) {(true) in
            self.pageControl.currentPage = self.currentIndex
        }
    }

    func configurePageControl() {
        if kasamType == "complex" {
            let pageControlCover = UIView()
            pageControl = UIPageControl(frame: CGRect(x: 0,y: UIScreen.main.bounds.maxY - 60,width: UIScreen.main.bounds.width,height: 20))
            pageControlCover.frame = CGRect.init(x: 0, y: UIScreen.main.bounds.maxY - 60, width: UIScreen.main.bounds.width, height: 60)
            pageControl.numberOfPages = orderedViewControllers.count
            pageControl.currentPage = 0
            pageControl.tintColor = UIColor.black
            pageControl.pageIndicatorTintColor = UIColor.lightGray
            pageControlCover.backgroundColor = UIColor.white
            pageControl.currentPageIndicatorTintColor = UIColor.black
            pageControl.backgroundColor = UIColor.clear
            pageControl.isUserInteractionEnabled = true
            view.addSubview(pageControlCover)
            view.addSubview(pageControl)
        }
    }
    
    func newVc(viewController: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: viewController)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
        self.pageControl.currentPage = orderedViewControllers.index(of: pageContentViewController)!
//        self.pageControl.currentPage = pageViewController.viewControllers!.first!.view.tag //Page Index
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

extension NewKasamPageController: UIScrollViewDelegate {
    //prevents users from pulling views past the last controller (which shows up black)
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.bounces = false
    }
}
