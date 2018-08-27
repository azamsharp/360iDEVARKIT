//
//  ViewController.swift
//  360iDevPresentation
//
//  Created by Mohammad Azam on 8/23/18.
//  Copyright © 2018 Mohammad Azam. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum BodyType :Int {
    case bear = 1
    case bullet = 2
    case plane = 3
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    private var isShootingEnabled :Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        sceneView.autoenablesDefaultLighting = true
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        //addBox()
        //addSphere()
        
        //addVirtualModel()
        
        setupUI()
        
        registerGestureRecognizers()
    }
    
    private func registerGestureRecognizers() {
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func tapped(recognizer :UITapGestureRecognizer) {
        
        let sceneView = recognizer.view as! ARSCNView
        let touch = recognizer.location(in: sceneView)
        
        if !self.isShootingEnabled {
        
        if let hitTestResult = sceneView.hitTest(touch, types: .existingPlane).first {
            
            let bearScene = SCNScene(named: "bear.dae")!
            let bearNode = bearScene.rootNode.childNode(withName: "bear", recursively: true)!
            bearNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            bearNode.physicsBody?.categoryBitMask = BodyType.bear.rawValue
            
            bearNode.position = SCNVector3(hitTestResult.worldTransform.columns.3.x, hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
            
            self.sceneView.scene.rootNode.addChildNode(bearNode)
        }
            
        } else {
            shoot()
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if anchor is ARPlaneAnchor {
            
            let plane = SCNPlane(width: 0.5, height: 0.5)
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named :"overlay_grid.png")
            material.isDoubleSided = true
            
            plane.firstMaterial = material
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.position = SCNVector3(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
            
            planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            planeNode.physicsBody?.categoryBitMask = BodyType.plane.rawValue
            planeNode.eulerAngles.x = .pi/2
            
            
            self.sceneView.scene.rootNode.addChildNode(planeNode)
            //node.addChildNode(planeNode)
        }
        
    }
    
    
    private func shoot() {
        
        guard let currentFrame = self.sceneView.session.currentFrame else {
            return
        }
        
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.3
        
        let box = SCNBox(width: 0.05, height: 0.05, length: 0.05, chamferRadius: 0)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.yellow
        
        let boxNode = SCNNode(geometry: box)
        boxNode.name = "Bullet"
        boxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        boxNode.physicsBody?.categoryBitMask = BodyType.bullet.rawValue
        boxNode.physicsBody?.isAffectedByGravity = false
        
        boxNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
        
        let forceVector = SCNVector3(boxNode.worldFront.x * 2,boxNode.worldFront.y * 2,boxNode.worldFront.z * 2)
        
        boxNode.physicsBody?.applyForce(forceVector, asImpulse: true)
        self.sceneView.scene.rootNode.addChildNode(boxNode)
        
    }
    
    private func addVirtualModel() {
    
        let bearScene = SCNScene(named: "bear.dae")!
        let bearNode = bearScene.rootNode.childNode(withName: "bear", recursively: true)!
        
        bearNode.position = SCNVector3(0, 0, -0.8)
        
        self.sceneView.scene.rootNode.addChildNode(bearNode)
    }
    
    private func addSphere() {
        
        let sphere = SCNSphere(radius: 0.3)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named :"earth.jpg")
        
        sphere.firstMaterial = material
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(0, 0, -0.5)
        
        let rotateAction = SCNAction.rotateBy(x: 0, y: 0.25, z: 0, duration: 1.0)
        let repeatAction = SCNAction.repeatForever(rotateAction)
        
        sphereNode.runAction(repeatAction)
        
        self.sceneView.scene.rootNode.addChildNode(sphereNode)
        
    }
    
    private func addBox() {
        
        let box = SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.purple
        box.materials = [material]
        
        let boxNode = SCNNode(geometry: box)
        boxNode.position = SCNVector3(0, 0, -0.5)
        
        self.sceneView.scene.rootNode.addChildNode(boxNode)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    private func setupUI() {
        
        let throwingChairSwitchControl = UISwitch(frame: CGRect.zero)
        throwingChairSwitchControl.translatesAutoresizingMaskIntoConstraints = false
        
        throwingChairSwitchControl.addTarget(self, action: #selector(shootingEnabledValueChanged), for: .valueChanged)
        
        self.sceneView.addSubview(throwingChairSwitchControl)
        
        // add constraints
        throwingChairSwitchControl.widthAnchor.constraint(equalToConstant: 100).isActive = true
        throwingChairSwitchControl.heightAnchor.constraint(equalToConstant: 44).isActive = true
        throwingChairSwitchControl.leftAnchor.constraint(equalTo: self.sceneView.leftAnchor, constant:  20).isActive = true
        throwingChairSwitchControl.topAnchor.constraint(equalTo: self.sceneView.topAnchor, constant: 20).isActive = true
        
    }
    
    @objc func shootingEnabledValueChanged(switchControl :UISwitch) {
        self.isShootingEnabled = switchControl.isOn
    }

}
