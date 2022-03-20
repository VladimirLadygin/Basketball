//
//  ViewController.swift
//  Basketball
//
//  Created by Владимир Ладыгин on 19.03.2022.
//


import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: -Outlets
    
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: -Properites
    
    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()
    
    var isHoopAdded = false {
        didSet {
//            configuration.planeDetection = [] //code disabled for game world tracking
            sceneView.session.run(configuration, options: .removeExistingAnchors)
        }
    }
    // MARK: -UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Detect vertical planes
        configuration.planeDetection = [.vertical, .horizontal]
        
        // Add people occlusion
        configuration.frameSemantics.insert(.personSegmentationWithDepth)
                
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    // MARK - Methods
    
    func getBall() -> SCNNode? {
        // Get current frame
        guard let frame = sceneView.session.currentFrame else { return nil }
        // Get camera transorm
        let cameraTransform = frame.camera.transform
        let matrixCameraTransform = SCNMatrix4(cameraTransform)
        // Create ball geometry
        let ball = SCNSphere(radius: 0.125)
        ball.firstMaterial?.diffuse.contents = UIImage(named:"basketball")
        // Create ball node
        let ballNode = SCNNode(geometry: ball)
        
        // Add physicsBody
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ballNode))
        // Calculate matrix force for pushing ball
        let power = Float(6)
        let x = -matrixCameraTransform.m31 * power
        let y = -matrixCameraTransform.m32 * power
        let z = -matrixCameraTransform.m33 * power
        let forceDirection = SCNVector3(x, y, z)
        // Apply force
        ballNode.physicsBody?.applyForce(forceDirection, asImpulse: true)
        // Assign camera position to ball
        ballNode.simdTransform = frame.camera.transform
        
        return ballNode
    }
    
    func getHoopNode() ->SCNNode {
        let scene = SCNScene(named: "Hoop.scn", inDirectory: "art.scnassets")!
        
        let hoopNode = scene.rootNode.clone()
        
        hoopNode.physicsBody = SCNPhysicsBody(
            type: .static,
            shape: SCNPhysicsShape(
                node: hoopNode,
                options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        
        return hoopNode
    }
    
    func getPlane(for anchor: ARPlaneAnchor) -> SCNNode {
        let extent = anchor.extent
        let plane = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
        plane.firstMaterial?.diffuse.contents = UIColor.green
        
        //Create 25% transpatrent plane node
        let planeNode = SCNNode(geometry: plane)
        planeNode.opacity = 0.25
        
        //Rotate plane node
        planeNode.eulerAngles.x -= .pi / 2
        
        // Add phisics for plane nodes
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: plane))
        
        return planeNode
    }
    
    func updatePlaneNode(_ node:SCNNode, for anchor: ARPlaneAnchor) {
        guard let planeNode = node.childNodes.first, let plane = planeNode.geometry as? SCNPlane else { return }
        //Change plane node center
        planeNode.simdPosition = anchor.center
        //Change plane node size
        let extent = anchor.extent
        plane.height = CGFloat(extent.z)
        plane.width = CGFloat(extent.x)
        
        if isHoopAdded {
            planeNode.opacity = 0
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else {return}
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        //Add hit hoop to the detected vertical plane
        node.addChildNode(getPlane(for: planeAnchor))
        
    }
    func renderer( _ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        // Update plane node
        updatePlaneNode(node, for: planeAnchor)
    }
    
    
    @IBAction func userTapped(_ sender: UITapGestureRecognizer) {
        if isHoopAdded {
            // Get ball node
            guard let ballNode = getBall() else { return }
            // Add ball on the camera position
            sceneView.scene.rootNode.addChildNode(ballNode)
            
        } else {
            let location = sender.location(in: sceneView )
            
            guard let result = sceneView.hitTest(location, types: .existingPlaneUsingExtent).first else { return }
            
            guard let anchor = result.anchor as? ARPlaneAnchor, anchor.alignment == .vertical else { return }
            
            // Get hope node and set its coordinates tp the point of user touch
            let hoopNode = getHoopNode()
            hoopNode.simdTransform = result.worldTransform
            // Hoopnode make is vertical
            hoopNode.eulerAngles.x -= .pi / 2
            
            isHoopAdded = true
            //Add hoop to planeAnchor
            sceneView.scene.rootNode.addChildNode(hoopNode)
            
        }
        
    }
}


