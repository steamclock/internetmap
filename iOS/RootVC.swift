//
//  RootVC.swift
//  Internet Map
//
//  Created by Nigel Brooke on 2017-11-16.
//  Copyright © 2017 Peer1. All rights reserved.
//

import UIKit
import ARKit

private class CameraDelegate: NSObject, ARSessionDelegate, ARSCNViewDelegate {
    let renderer: ViewController
    var modelPos = GLKVector3Make(0.0, 0.0, 0.0)

    init(renderer: ViewController) {
        self.renderer = renderer
        super.init()
    }

    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let orientation = UIApplication.shared.statusBarOrientation
        let view = renderer.view as! GLKView
        let size = CGSize(width: view.drawableWidth, height: view.drawableHeight)

        renderer.overrideCamera(frame.camera.viewMatrix(for: orientation), projection: frame.camera.projectionMatrix(for: orientation, viewportSize: size, zNear: 0.05, zFar: 100), modelPos:modelPos)
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print(anchor)
        /*
        let planeGeometry = SCNPlane(width: anchor. .extent.x, height: anchor.extent.z)
        var planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        planeNode.transform = SCNMatrix4MakeRotation(-.pi / 2.0, 1.0, 0.0, 0.0)
        node.addChildNode(planeNode)
         */
    }
}

public class RootVC: UIViewController {
    private var rendererVC: ViewController!
    private var arkitView: ARSCNView!
    private var cameraDelegate : CameraDelegate!

   public override func viewDidLoad() {
        super.viewDidLoad()

        arkitView = ARSCNView()
        arkitView.frame = view.frame
        view.addSubview(arkitView)

        if UIDevice.current.userInterfaceIdiom == .phone {
            rendererVC = ViewController(nibName: "ViewController_iPhone", bundle: nil)
        }
        else {
            rendererVC = ViewController(nibName: "ViewController_iPad", bundle: nil)
        }

        rendererVC.view.frame = view.frame
        view.addSubview(rendererVC.view)
        addChildViewController(rendererVC)

        let reset = UITapGestureRecognizer(target: self, action: #selector(resetPosition))
        reset.numberOfTapsRequired = 3

        rendererVC.view.addGestureRecognizer(reset)

        cameraDelegate = CameraDelegate(renderer: rendererVC)
        arkitView.session.delegate = cameraDelegate
        arkitView.delegate = cameraDelegate

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arkitView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        arkitView.session.run(configuration)
    }

    @objc func resetPosition() {
        let hit = arkitView.hitTest(rendererVC.view.center, types: .estimatedHorizontalPlane).first

        if let hit = hit {
            let point = hit.worldTransform.columns.3
            cameraDelegate.modelPos = GLKVector3Make(point.x, point.y + 0.5, point.z)
        }
        print("foo")
    }
}
