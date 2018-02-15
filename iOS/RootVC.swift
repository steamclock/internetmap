//
//  RootVC.swift
//  Internet Map
//
//  Created by Nigel Brooke on 2017-11-16.
//  Copyright © 2017 Peer1. All rights reserved.
//

import UIKit
import ARKit

private class CameraDelegate: NSObject, ARSessionDelegate {
    let renderer: ViewController
    let cameraImage: UIImageView
    weak var root: RootVC?

    var modelPos = GLKVector3Make(0.0, 0.0, 0.0)

    init(root: RootVC, cameraImage: UIImageView, renderer: ViewController) {
        self.root = root
        self.renderer = renderer
        self.cameraImage = cameraImage
        super.init()
    }

    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        root?.updatePlacement()

        let orientation = UIApplication.shared.statusBarOrientation
        let view = renderer.view as! GLKView
        let size = CGSize(width: view.drawableWidth, height: view.drawableHeight)

        renderer.overrideCamera(frame.camera.viewMatrix(for: orientation), projection: frame.camera.projectionMatrix(for: orientation, viewportSize: size, zNear: 0.05, zFar: 100), modelPos:modelPos)

        let cameraOrientation: CGImagePropertyOrientation = UIDevice.current.userInterfaceIdiom == .phone ? .right : .up
        cameraImage.image = UIImage(ciImage: CIImage(cvPixelBuffer: frame.capturedImage).oriented(cameraOrientation))
    }
}

public class RootVC: UIViewController {
    private var rendererVC: ViewController!
    private var imageView: UIImageView?
    private var arSession: ARSession?
    private var placing = false
    private var cameraDelegate : CameraDelegate?

    public override func viewDidLoad() {
        super.viewDidLoad()
        rendererVC = childViewControllers.first as! ViewController
    }

    func toggleAR() {
        if imageView == nil {
            enableAR()
        }
        else {
            disableAR()
        }
    }

    func enableAR() {
        let image = UIImageView()
        image.frame = view.frame
        view.addSubview(image)
        view.sendSubview(toBack: image)
        imageView = image

        cameraDelegate = CameraDelegate(root: self, cameraImage: image, renderer: rendererVC)
        arSession = ARSession()
        arSession?.delegate = cameraDelegate

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arSession?.run(configuration)

        rendererVC.enableAR(true)
        //rendererVC.enableRendering(false)
        rendererVC.enablePlacementOverlay(true)

        placing = true
    }

    func disableAR() {
        imageView?.removeFromSuperview()
        imageView = nil
        cameraDelegate = nil
        rendererVC.enableAR(false)
    }

    func updatePlacement() {
        guard placing, let arSession = arSession, let cameraDelegate = cameraDelegate else {
            return
        }

        let hit = arSession.currentFrame?.hitTest(CGPoint(x: 0.5, y:0.5), types: .estimatedHorizontalPlane).first

        if let hit = hit {
            let point = hit.worldTransform.columns.3
            let heightAboveGround : Float = 1.0 // height above ground (of center of object, i.e. equator for globe)
            cameraDelegate.modelPos = GLKVector3Make(point.x, point.y + heightAboveGround, point.z)
        }
    }

    @objc func startPlacement() {
        placing = true
        //rendererVC.enableRendering(false)
        rendererVC.enablePlacementOverlay(true)
    }

    @objc func endPlacement() {
        placing = false
        //rendererVC.enableRendering(true)
        rendererVC.enablePlacementOverlay(false)
    }
}
