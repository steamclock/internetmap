//
//  RootVC.swift
//  Internet Map
//
//  Created by Nigel Brooke on 2017-11-16.
//  Copyright © 2017 Peer1. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

public class RootVC: UIViewController {
    var rendererVC: ViewController!
    var arkitView: ARSCNView!

   public override func viewDidLoad() {
        super.viewDidLoad()

        arkitView = ARSCNView()
        arkitView.frame = view.frame
        view.addSubview(arkitView)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arkitView.session.run(configuration)

        if UIDevice.current.userInterfaceIdiom == .phone {
            rendererVC = ViewController(nibName: "ViewController_iPhone", bundle: nil)
        }
        else {
            rendererVC = ViewController(nibName: "ViewController_iPad", bundle: nil)
        }

        rendererVC.view.frame = view.frame
        view.addSubview(rendererVC.view)
        addChildViewController(rendererVC)


        // Do any additional setup after loading the view.
    }

}
