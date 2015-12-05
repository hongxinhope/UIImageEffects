//
//  ImageEffectsViewController.swift
//  UIImageEffects
//
//  Created by 洪鑫 on 15/12/6.
//  Copyright © 2015年 Xin Hong. All rights reserved.
//

import UIKit

class ImageEffectsViewController: UIViewController, UIPageViewControllerDataSource {
    var pageTitles = [String]()
    var images = [UIImage]()
    let pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: [:])

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        initData()
        setupUI()
    }

    // MARK: - Helper
    private func initData() {
        pageTitles = ["Origin", "Light Effect", "Extra Light Effect", "Dark Effect", "Cyan Tint Color"]

        let originalImage = UIImage(named: "ExampleImage")
        let lightEffectImage = originalImage?.applyLightEffect() ?? originalImage
        let extraLightEffectImage = originalImage?.applyExtraLightEffect() ?? originalImage
        let darkEffectImage = originalImage?.applyDarkEffect() ?? originalImage
        let tintColorImage = originalImage?.applyTintEffect(tintColor: UIColor.cyanColor()) ?? originalImage
        images = [originalImage!, lightEffectImage!, extraLightEffectImage!, darkEffectImage!, tintColorImage!]
    }

    private func setupUI() {
        pageViewController.dataSource = self
        pageViewController.view.frame = view.frame

        let originalImageViewController = viewControllerAtIndex(0)
        let viewControllers = [originalImageViewController!]
        pageViewController.setViewControllers(viewControllers, direction: .Forward, animated: false, completion: nil)

        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMoveToParentViewController(self)
    }

    private func viewControllerAtIndex(index:  Int) -> PageContentViewController? {
        if pageTitles.count == 0 || index >= pageTitles.count {
            return nil
        }

        let pageContentViewController = storyboard!.instantiateViewControllerWithIdentifier("PageContentViewController") as! PageContentViewController
        pageContentViewController.titleText = pageTitles[index]
        pageContentViewController.image = images[index]
        pageContentViewController.pageIndex = index
        return pageContentViewController
    }

    // MARK: - UIPageViewController data source
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let viewController = viewController as? PageContentViewController {
            if viewController.pageIndex == 0 || viewController.pageIndex == NSNotFound {
                return nil
            }
            return viewControllerAtIndex(viewController.pageIndex - 1)
        }
        return nil
    }

    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let viewController = viewController as? PageContentViewController {
            if viewController.pageIndex == pageTitles.count || viewController.pageIndex == NSNotFound {
                return nil
            }
            return viewControllerAtIndex(viewController.pageIndex + 1)
        }
        return nil
    }

    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return pageTitles.count
    }

    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
