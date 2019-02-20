//
//  CreditsViewController.swift
//  Internet Map
//
//  Created by Nigel Brooke on 2017-11-08.
//  Copyright © 2017 Peer1. All rights reserved.
//

import UIKit

public class CreditsViewController: UIViewController, UIWebViewDelegate {
    @objc public var informationType = ""
    @objc public var delegate: AnyObject?

    private var webView: UIWebView!
    private var aboutMoreButton: UIButton?
    
    class func currentSize() -> CGSize {
        return CreditsViewController.size(in: UIApplication.shared.statusBarOrientation)
    }
    
    class func size(in orientation: UIInterfaceOrientation) -> CGSize {
        var size: CGSize = UIScreen.main.bounds.size

        if orientation.isLandscape {
            size = CGSize(width: size.height, height: size.width)
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
            webView.scrollView.isScrollEnabled = false
        }
        else {
            webViewFrame.size.width = UIScreen.main.bounds.size.width - 20
        }

        webView.frame = webViewFrame

        var filePath: String

        if informationType == "about" {
            filePath = Bundle.main.path(forResource: "about", ofType: "html") ?? ""
        }
        else if informationType == "contact" {
            filePath = Bundle.main.path(forResource: "contact", ofType: "html") ?? ""
        }
        else {
            filePath = Bundle.main.path(forResource: "credits", ofType: "html") ?? ""
        }

        let html = try? String(contentsOfFile: filePath, encoding: .utf8)

        if html != nil {
            webView.loadHTMLString(html ?? "", baseURL: nil)
        }

        webView.backgroundColor = UIColor.clear
        webView.isOpaque = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.indicatorStyle = .white
        // Start webview faded out, load happens async, and this way we can fade it in rather
        // than popping when the load finishes. Slightly less jarring that way.
        webView.alpha = 0.00
        webView.delegate = self
        view.addSubview(webView)

        //Done button
        let xImage = UIImage(named: "x-icon")!
        let doneButtonWidth = xImage.size.width + 20
        let doneButtonHeight = xImage.size.height + 20
        let doneButton = UIButton(type: .custom)
        let doneFrame = CGRect(x: UIScreen.main.bounds.size.width - (xImage.size.width + 20), y: 20, width: doneButtonWidth, height: doneButtonHeight)
        doneButton.frame = doneFrame
        doneButton.imageView?.contentMode = .center
        doneButton.setImage(xImage, for: .normal)
        doneButton.addTarget(self, action: #selector(self.close), for: .touchUpInside)
        doneButton.backgroundColor = Theme.primary
        doneButton.layer.cornerRadius = doneButton.frame.size.height / 2
        view.addSubview(doneButton)

        let guide = self.view.safeAreaLayoutGuide

        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.topAnchor.constraint(equalTo: guide.topAnchor, constant:10).isActive = true
        doneButton.heightAnchor.constraint(equalToConstant: doneButtonHeight).isActive = true
        doneButton.widthAnchor.constraint(equalToConstant: doneButtonWidth).isActive = true
        doneButton.rightAnchor.constraint(equalTo: guide.rightAnchor, constant: -15).isActive = true

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: guide.topAnchor, constant:0).isActive = true
        webView.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant:0).isActive = true
        webView.leftAnchor.constraint(equalTo: guide.leftAnchor, constant:20).isActive = true
        webView.rightAnchor.constraint(equalTo: guide.rightAnchor, constant:-20).isActive = true

        super.viewDidLoad()
    }
    
    func createContactButtonForAbout() {
        let aboutMoreButton = UIButton(type: .system)
        let aboutMoreButtonHeight: CGFloat = 50
        aboutMoreButton.setTitleColor(UIColor.white, for: .normal)
        aboutMoreButton.setTitle(NSLocalizedString("Visit cogecopeer1.com", comment: ""), for: .normal)
        aboutMoreButton.backgroundColor = Theme.primary
        aboutMoreButton.titleLabel?.font = UIFont(name: Theme.fontNameLight, size: 19)!
        var contactButtonWidth: CGFloat = UIScreen.main.bounds.size.width
        if UIScreen.main.bounds.size.width > 300 {
            contactButtonWidth = 300
        }
        let contactFrame = CGRect(x: UIScreen.main.bounds.size.width / 2 - (contactButtonWidth / 2), y: UIScreen.main.bounds.size.height - 60, width: contactButtonWidth, height: aboutMoreButtonHeight)
        aboutMoreButton.frame = contactFrame
        aboutMoreButton.layer.cornerRadius = aboutMoreButton.frame.size.height / 2
        aboutMoreButton.addTarget(self, action: #selector(self.aboutMore), for: .touchUpInside)

        self.aboutMoreButton = aboutMoreButton

        view.addSubview(aboutMoreButton)

        // iPhoneX support
        if #available(iOS 11.0, *) {
            aboutMoreButton.translatesAutoresizingMaskIntoConstraints = false
            let guide = self.view.safeAreaLayoutGuide
            aboutMoreButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant:-10).isActive = true
            aboutMoreButton.heightAnchor.constraint(equalToConstant: aboutMoreButtonHeight).isActive = true
            aboutMoreButton.widthAnchor.constraint(equalToConstant: contactButtonWidth).isActive = true
            aboutMoreButton.centerXAnchor.constraint(equalToSystemSpacingAfter: guide.centerXAnchor, multiplier: 1.0).isActive = true
        }
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

        let sel = #selector(ViewController.moreAboutCogeco)

        if delegate?.responds(to: sel) ?? false {
            _ = delegate?.perform(sel)
        }
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

}
