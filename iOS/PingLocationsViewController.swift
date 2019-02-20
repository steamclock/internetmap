//
//  PingLocationsViewController.swift
//  Internet Map
//
//  Created by Robert MacEachern on 2019-02-19.
//  Copyright © 2019 Peer1. All rights reserved.
//

import UIKit

class PingLocationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let backgroundImageView = UIImageView(image: Theme.settingsItemBackgroundImage())
        view.addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundImageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let doneButton = DoneButton(frame: .zero)
        doneButton.addTarget(self, action: #selector(self.close), for: .touchUpInside)
        view.addSubview(doneButton)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant:10).isActive = true
        doneButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -15).isActive = true
    }

    @objc private func close() {
        dismiss(animated: true, completion: nil)
    }

}
