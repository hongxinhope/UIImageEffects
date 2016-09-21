//
//  ImageEffectsViewController.swift
//  UIImageEffects
//
//  Created by 洪鑫 on 15/12/6.
//  Copyright © 2015年 Xin Hong. All rights reserved.
//

import UIKit
import UIImageEffects

class ImageEffectsViewController: UIViewController, UIPageViewControllerDataSource {
    var pageTitles = [String]()
    var images = [UIImage]()
    let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        initData()
        setupUI()
    }

    // MARK: - Helper
    fileprivate func initData() {
        pageTitles = ["Origin", "Light Effect", "Extra Light Effect", "Dark Effect", "Cyan Tint Color"]

        let originalImage = #imageLiteral(resourceName: "ExampleImage")
        let lightEffectImage = originalImage.applyLightEffect() ?? originalImage
        let extraLightEffectImage = originalImage.applyExtraLightEffect() ?? originalImage
        let darkEffectImage = originalImage.applyDarkEffect() ?? originalImage
        let tintColorImage = originalImage.applyTintEffect(with: UIColor.cyan) ?? originalImage
        images = [originalImage, lightEffectImage, extraLightEffectImage, darkEffectImage, tintColorImage]
    }

    fileprivate func setupUI() {
        pageViewController.dataSource = self
        pageViewController.view.frame = view.frame

        let originalImageViewController = viewControllerAt(0)
        let viewControllers = [originalImageViewController!]
        pageViewController.setViewControllers(viewControllers, direction: .forward, animated: false, completion: nil)

        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParentViewController: self)
    }

    fileprivate func viewControllerAt(_ index:  Int) -> PageContentViewController? {
        if pageTitles.count == 0 || index >= pageTitles.count {
            return nil
        }

        let pageContentViewController = storyboard!.instantiateViewController(withIdentifier: "PageContentViewController") as! PageContentViewController
        pageContentViewController.titleText = pageTitles[index]
        pageContentViewController.image = images[index]
        pageContentViewController.pageIndex = index
        return pageContentViewController
    }

    // MARK: - UIPageViewController data source
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let viewController = viewController as? PageContentViewController {
            if viewController.pageIndex == NSNotFound {
                return nil
            }
            if viewController.pageIndex == 0  {
                return viewControllerAt(pageTitles.count - 1)
            }
            return viewControllerAt(viewController.pageIndex - 1)
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let viewController = viewController as? PageContentViewController {
            if viewController.pageIndex == NSNotFound {
                return nil
            }
            if viewController.pageIndex == pageTitles.count - 1 {
                return viewControllerAt(0)
            }
            return viewControllerAt(viewController.pageIndex + 1)
        }
        return nil
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pageTitles.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
