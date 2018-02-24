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

        let cameraOrientation: CGImagePropertyOrientation = UIDevice.current.userInterfaceIdiom == .phone ? .right : (orientation == .landscapeRight ? .up : .down)
        cameraImage.image = UIImage(ciImage: CIImage(cvPixelBuffer: frame.capturedImage).oriented(cameraOrientation))
    }
}

public class RootVC: UIViewController {
    private var rendererVC: ViewController!
    private var imageView: UIImageView?
    private var arSession: ARSession?
    private var cameraDelegate : CameraDelegate?

    private var mode: ARMode = .disabled {
        didSet {
            if mode != .disabled && arSession == nil {
                setupSession()
            }

            if mode == .disabled {
                imageView?.removeFromSuperview()
                imageView = nil
                cameraDelegate = nil
                arSession = nil
            }

            rendererVC.setARMode(mode)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        rendererVC = childViewControllers.first as! ViewController
    }

    func toggleAR() {
        if mode == .disabled {
            mode = .searching
        }
        else {
            mode = .disabled
        }
    }

    func setupSession() {
        let image = UIImageView()
        image.frame = view.frame
        image.alpha = 0.5
        view.addSubview(image)
        view.sendSubview(toBack: image)
        imageView = image

        cameraDelegate = CameraDelegate(root: self, cameraImage: image, renderer: rendererVC)
        arSession = ARSession()
        arSession?.delegate = cameraDelegate

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arSession?.run(configuration)
    }

    func updatePlacement() {
        guard mode == .searching || mode == .placing,
              let arSession = arSession,
              let cameraDelegate = cameraDelegate,
              let plane = arSession.currentFrame?.anchors.first as? ARPlaneAnchor else {
            return
        }

        if mode == .searching {
            mode = .placing
        }

        let orientation = UIApplication.shared.statusBarOrientation
        let globeRadius : Float = 0.5

        if let view = arSession.currentFrame?.camera.viewMatrix(for: orientation) {
            let camera =  matrix_invert(view)
            let translateRaw = camera.columns.3
            let translate = GLKVector3Make(translateRaw.x, translateRaw.y, translateRaw.z)

            let forwardRaw = camera.columns.2
            let forward = GLKVector3Make(-forwardRaw.x, -forwardRaw.y, -forwardRaw.z)
            let scaledForward = GLKVector3MultiplyScalar(forward, 2)

            var position = GLKVector3Add(translate, scaledForward)
            let floor = plane.transform.columns.3.y

            if position.y - globeRadius < floor {
                position.y = floor + globeRadius
            }

            cameraDelegate.modelPos = position
        }
    }

    @objc func startPlacement() {
        if mode == .viewing {
            mode = .placing
        }
    }

    @objc func endPlacement() {
        if mode == .placing {
            mode = .viewing
        }
    }
}
