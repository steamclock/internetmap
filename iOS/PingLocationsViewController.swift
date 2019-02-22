//
//  PingLocationsViewController.swift
//  Internet Map
//
//  Created by Robert MacEachern on 2019-02-19.
//  Copyright © 2019 Peer1. All rights reserved.
//

import UIKit

@objc protocol PingLocationsDelegate {
    func pingLocationsViewController(_ pingLocationsViewController: PingLocationsViewController, selectedHostName hostName: String)
}

class PingLocationsViewController: UIViewController {

    @objc var delegate: PingLocationsDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let backgroundImageView = UIImageView(image: Theme.settingsItemBackgroundImage())
        view.addSubview(backgroundImageView)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundImageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.alwaysBounceVertical = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 65))
        tableView.tableHeaderView = tableHeaderView

        let headerLabel = UILabel(frame: .zero)
        headerLabel.text = "Ping Cogeco Peer 1"
        headerLabel.textColor = .white
        headerLabel.font = UIFont(name: Theme.fontNameLight, size: 30)
        tableHeaderView.addSubview(headerLabel)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.leftAnchor.constraint(equalTo: tableHeaderView.leftAnchor, constant: 16).isActive = true
        headerLabel.topAnchor.constraint(equalTo: tableHeaderView.topAnchor).isActive = true
        let rightConstraint = headerLabel.rightAnchor.constraint(equalTo: tableHeaderView.rightAnchor)
        rightConstraint.priority = UILayoutPriority(999)
        rightConstraint.isActive = true
        headerLabel.bottomAnchor.constraint(equalTo: tableHeaderView.bottomAnchor).isActive = true

        let doneButton = DoneButton(frame: .zero)
        doneButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(doneButton)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant:10).isActive = true
        doneButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -15).isActive = true
    }

    @objc private func close() {
        dismiss(animated: true, completion: nil)
    }
}

extension PingLocationsViewController: UITableViewDataSource {

    var rows: [(String, String)] {
        return [
            ("Cogeco Peer 1", "www.cogecopeer1.com"),
            ("Google", "www.google.com"),
            ("Yahoo", "www.yahoo.com")
        ]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .clear
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = UIColor(white: 1.0, alpha: 0.3)
        let row = rows[indexPath.row]
        cell.textLabel?.text = row.0
        cell.textLabel?.font = UIFont(name: Theme.fontNameLight, size: 20)
        return cell
    }
}

extension PingLocationsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = rows[indexPath.row]
        dismiss(animated: true) {
            self.delegate?.pingLocationsViewController(self, selectedHostName: row.1)
        }
    }
}
