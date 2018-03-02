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

        renderer.overrideCamera(frame.camera.viewMatrix(for: orientation), projection: frame.camera.projectionMatrix(for: orientation, viewportSize: size, zNear: CGFloat(renderer.nearPlane()), zFar: CGFloat(renderer.farPlane())), modelPos:modelPos)

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
        guard ARConfiguration.isSupported else { return NSLog("Attempted to set up AR session for unsupported device.") }
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
              let view = arSession.currentFrame?.camera.viewMatrix(for: UIApplication.shared.statusBarOrientation),
              let planes = arSession.currentFrame?.anchors.flatMap({ $0 as? ARPlaneAnchor}),
              !planes.isEmpty else {
            return
        }

        // If we've got this far, we have an AR "fix" so can switch out of search into palcement
        if mode == .searching {
            mode = .placing
        }

        // Calulate position 2m in fornt of camera to pplace map
        let camera = view.inverse
        let translate = camera.columns.3
        let forward = camera.columns.2 * -1
        var position = translate + (forward * 2)

        let globeRadius : Float = 0.5 // TODO: should be getting this from the map data

        // Check if placement position is above any detected planes, and correct position upwards if needed.
        for plane in planes {
            let positionOnPlane =  plane.transform.inverse * position

            if (abs(positionOnPlane.x - plane.center.x) < plane.extent.x) && (abs(positionOnPlane.z - plane.center.z) < plane.extent.z) {
                let height = plane.transform.columns.3.y

                if position.y - globeRadius < height {
                    position.y = height + globeRadius
                }
            }
        }

        // Always make sure it is at least aboce the lowest detected height, independant of plane extents
        let minHeight = planes.reduce(Float.greatestFiniteMagnitude) { (height, plane) in plane.transform.columns.3.y < height ? plane.transform.columns.3.y : height }

        if position.y - globeRadius < minHeight {
            position.y = minHeight + globeRadius
        }

        cameraDelegate.modelPos = GLKVector3Make(position.x, position.y, position.z)
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
