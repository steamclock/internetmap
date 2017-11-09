//
//  CreditsViewController.swift
//  Internet Map
//
//  Created by Nigel Brooke on 2017-11-08.
//  Copyright © 2017 Peer1. All rights reserved.
//

import UIKit

public class CreditsViewController: UIViewController, UIWebViewDelegate {
    public var informationType = ""
    public var delegate: AnyObject?

    private var webView: UIWebView?
    private var aboutMoreButton: UIButton?
    
    class func currentSize() -> CGSize {
        return CreditsViewController.size(in: UIApplication.shared.statusBarOrientation)
    }
    
    class func size(in orientation: UIInterfaceOrientation) -> CGSize {
        var size: CGSize = UIScreen.main.bounds.size
        let application = UIApplication.shared

        if UIInterfaceOrientationIsLandscape(orientation) {
            size = CGSize(width: size.height, height: size.width)
        }

        if application.isStatusBarHidden == false {
            size.height -= min(application.statusBarFrame.size.width, application.statusBarFrame.size.height)
        }

        return size
    }

    override public func viewDidLoad() {
        // Background image
        var backgroundImage: UIImage?

        if UIDevice.current.userInterfaceIdiom == .phone {
            backgroundImage = UIImage(named: "iphone-bg.png")
        }
        else {
            backgroundImage = UIImage(named: "ipad-bg.png")
        }

        let background = UIImageView(image: backgroundImage)
        background.isUserInteractionEnabled = true
        view = background

        // Webview for contents
        webView = UIWebView()
        var webViewFrame: CGRect = background.frame

        if (informationType == "about") {
            webViewFrame.size.height = CreditsViewController.currentSize().height - 60
        }
        else {
            webViewFrame.size.height = CreditsViewController.currentSize().height
        }

        if UIDevice.current.userInterfaceIdiom == .pad {
            // webViewFrame.origin.x += 300;
            webViewFrame.origin.x = UIScreen.main.bounds.size.width / 2 - 200
            webViewFrame.size.width -= 600
            webView?.scrollView.isScrollEnabled = false
        }
        else {
            webViewFrame.size.width = UIScreen.main.bounds.size.width - 20
        }

        webView?.frame = webViewFrame

        var filePath: String

        if informationType != nil && (informationType == "about") {
            filePath = Bundle.main.path(forResource: "about", ofType: "html") ?? ""
        }
        else if informationType != nil && (informationType == "contact") {
            filePath = Bundle.main.path(forResource: "contact", ofType: "html") ?? ""
        }
        else {
            filePath = Bundle.main.path(forResource: "credits", ofType: "html") ?? ""
        }

        let html = try? String(contentsOfFile: filePath, encoding: .utf8)

        if html != nil {
            webView?.loadHTMLString(html ?? "", baseURL: nil)
        }

        webView?.backgroundColor = UIColor.clear
        webView?.isOpaque = false
        webView?.scrollView.showsVerticalScrollIndicator = false
        webView?.scrollView.indicatorStyle = .white
        // Start webview faded out, load happens async, and this way we can fade it in rather
        // than popping when the load finishes. Slightly less jarring that way.
        webView?.alpha = 0.00
        webView?.delegate = self
        view.addSubview(webView ?? UIView())

        //Done button
        let xImage = UIImage(named: "x-icon")!
        let doneButton = UIButton(type: .custom)
        let doneFrame = CGRect(x: UIScreen.main.bounds.size.width - (xImage.size.width + 20), y: 0, width: xImage.size.width + 20, height: xImage.size.height + 20)
        doneButton.frame = doneFrame
        doneButton.imageView?.contentMode = .center
        doneButton.setImage(xImage, for: .normal)
        doneButton.addTarget(self, action: #selector(self.close), for: .touchUpInside)
        doneButton.backgroundColor = Theme.primary
        view.addSubview(doneButton)
        super.viewDidLoad()
    }
    
    func createContactButtonForAbout() {
        let aboutMoreButton = UIButton(type: .system)
        aboutMoreButton.setTitleColor(UIColor.white, for: .normal)
        aboutMoreButton.setTitle(NSLocalizedString("Visit cogecopeer1.com", comment: ""), for: .normal)
        aboutMoreButton.backgroundColor = Theme.primary
        aboutMoreButton.titleLabel?.font = UIFont(name: Theme.fontNameLight, size: 19)!
        var contactButtonWidth: CGFloat = UIScreen.main.bounds.size.width
        if UIScreen.main.bounds.size.width > 300 {
            contactButtonWidth = 300
        }
        let contactFrame = CGRect(x: UIScreen.main.bounds.size.width / 2 - (contactButtonWidth / 2), y: UIScreen.main.bounds.size.height - 60, width: contactButtonWidth, height: 45)
        aboutMoreButton.frame = contactFrame
        aboutMoreButton.layer.cornerRadius = aboutMoreButton.frame.size.height / 2
        aboutMoreButton.addTarget(self, action: #selector(self.aboutMore), for: .touchUpInside)

        self.aboutMoreButton = aboutMoreButton

        view.addSubview(aboutMoreButton)
    }

    public func webViewDidFinishLoad(_ webView: UIWebView) {
        UIView.animate(withDuration: 0.25, animations: {() -> Void in
            webView.alpha = 1.0
        })

        webView.scrollView.flashScrollIndicators()

        if (informationType == "about") {
            createContactButtonForAbout()
        }
    }

    @IBAction func close(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func aboutMore(_ sender: Any) {
        dismiss(animated: false)

        let sel = Selector("moreAboutCogeco")

        if delegate?.responds(to: sel) ?? false {
            _ = delegate?.perform(sel)
        }
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .pad ? .landscape : .portrait
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // the suggested not depreciated call does not seem to work
        UIApplication.shared.setStatusBarHidden(true, with: .none)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // the suggested not depreciated call does not seem  to work
        UIApplication.shared.setStatusBarHidden(false, with: .none)
    }

}
