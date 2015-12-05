//
//  PageContentViewController.swift
//  UIImageEffects
//
//  Created by 洪鑫 on 15/12/5.
//  Copyright © 2015年 Xin Hong. All rights reserved.
//

import UIKit

class PageContentViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    var pageIndex = 0
    var titleText: String?
    var image: UIImage?

    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Helper
    private func setupUI() {
        titleLabel.text = titleText
        imageView.image = image
    }
}

