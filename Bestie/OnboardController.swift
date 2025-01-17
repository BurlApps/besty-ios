
//
//  OnboardControllerViewController.swift
//  Bestie
//
//  Created by Brian Vallelunga on 9/30/15.
//  Copyright © 2015 Brian Vallelunga. All rights reserved.
//

import UIKit
import Mixpanel

class OnboardController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var user: User!
    var nextPage = 1
    var mixpanel: Mixpanel!
    
    private var currentPage = 0
    private var controllers: [OnboardPageController] = []
    private var storyBoard = UIStoryboard(name: "Main", bundle: nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.mixpanel = Mixpanel.sharedInstance()
        
        let backgroundView = UIView(frame: self.view.frame)
        let image = UIImage(named: "HeaderBackground")
        
        backgroundView.backgroundColor = UIColor(patternImage: image!)
        backgroundView.alpha = Globals.onboardAlpha
        self.view.insertSubview(backgroundView, atIndex: 0)
        self.view.backgroundColor = UIColor.whiteColor()
        
        self.dataSource = self
        self.delegate = self
        
        for controller in self.view.subviews {
            if let scrollView = controller as? UIScrollView {
                scrollView.scrollEnabled = false
            }
        }
        
        self.createPage("WelcomeController")
        self.createPage("SelectionController")
        
        Config.sharedInstance { (config) -> Void in
            self.nextPage = config.onboardNext
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.user = User.current()
        
        if self.user != nil {
            self.user.aliasMixpanel()
            self.performSegueWithIdentifier("finishedSegue", sender: self)
        } else {
            self.showController()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        let controller =  segue.destinationViewController as! PageController
            
        controller.startingPage = self.nextPage
    }
    
    func createPage(name: String) {
        let page = self.storyBoard.instantiateViewControllerWithIdentifier(name) as? OnboardPageController
        
        page?.pageIndex = self.controllers.count
        page?.onboardController = self
        
        self.controllers.append(page!)
    }
    
    func nextController() {
        self.currentPage += 1
        
        if self.currentPage >= self.controllers.count {
            self.currentPage = 0
            
            self.performSegueWithIdentifier("finishedSegue", sender: self)
            
            self.user.mixpanel.track("Mobile.Onboard.Finished", properties: [
                "Next": self.nextPage == 1 ? "Vote" : "Upload"
            ])
        } else {
            self.showController()
        }
    }
    
    func showController() {
        if let controller = self.viewControllerAtIndex(self.currentPage) {
            self.setViewControllers([controller], direction: .Forward, animated: self.currentPage > 0, completion: nil)
        }
    }
    
    func viewControllerAtIndex(index: Int) -> OnboardPageController! {
        if index == NSNotFound && index > self.controllers.count {
            return nil
        }
        
        return self.controllers[index]
    }
    

    // MARK: Page View Controller Data Source
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let index = (viewController as! OnboardPageController).pageIndex
        return self.viewControllerAtIndex(index - 1)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let index = (viewController as! OnboardPageController).pageIndex
        return self.viewControllerAtIndex(index + 1)
    }
}
