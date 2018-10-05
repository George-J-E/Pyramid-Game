//
//  GameViewController.swift
//  Pyramid Game
//
//  Created by George Elsham on 03/10/2018.
//  Copyright © 2018 George Elsham. All rights reserved.
//

import UIKit
import SceneKit


// MARK: Extension for Float
extension Float {
    /// Convert degrees to radians
    func asRadians() -> Float {
        return self * Float.pi / 180
    }
    /// Convert radians to degrees
    func asDegrees() -> Float {
        return self / Float.pi * 180
    }
}

// MARK: Extension for SCNVector3
extension SCNVector3 {
    /// Convert SCNVector3 degrees to radians
    func asRadians() -> SCNVector3 {
        return SCNVector3(self.x.asRadians(), self.y.asRadians(), self.z.asRadians())
    }
    
    /// Convert SCNVector3 radians to degrees
    func asDegrees() -> SCNVector3 {
        return SCNVector3(self.x.asDegrees(), self.y.asDegrees(), self.z.asDegrees())
    }
}

// MARK: Extension for SCNNode
extension SCNNode {
    /// Make node disappear with a fade
    func disappearWithFade(duration: TimeInterval = 0.5) {
        if self.name != "fadeOut" {
            self.name = "fadeOut"
            self.runAction(SCNAction.fadeOpacity(to: 0, duration: duration), completionHandler: {
                self.removeFromParentNode()
            })
        }
    }
    
    /// Look at a SCNVector3 point
    func lookAt(_ point: SCNVector3) {
        // Find change in positions
        let changeX = self.position.x - point.x // Change in X position
        let changeY = self.position.y - point.y // Change in Y position
        let changeZ = self.position.z - point.z // Change in Z position
        
        // Calculate the X and Y angles
        let angleX = atan2(changeZ, changeY) * (changeZ > 0 ? -1 : 1)
        let angleY = atan2(changeZ, changeX)
        
        // Calculate the X and Y rotations
        let xRot = Float(-90).asRadians() - angleX // X rotation
        let yRot = Float(90).asRadians() - angleY // Y rotation
        self.runAction(SCNAction.rotateTo(x: CGFloat(xRot), y: CGFloat(yRot), z: 0, duration: 0)) // Rotate
    }
}


// MARK: GameViewController class
class GameViewController: UIViewController, SCNSceneRendererDelegate {
    
    // MARK: Create game view and scene
    var gameView: SCNView!
    var gameScene: SCNScene!
    var cameraNode: SCNNode!
    var targetCreationTime: TimeInterval = 0
    
    
    // MARK: viewDidLoad() override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialise the game by calling the init functions
        initView()
        initScene()
        initCamera()
    }
    
    
    // MARK: Initialise the game view, scene and camera
    func initView() {
        gameView = self.view as? SCNView // Assign the view
        gameView.allowsCameraControl = false // Don't allow the player to move the camera
        gameView.showsStatistics = true // Show game statistics
        gameView.autoenablesDefaultLighting = true // Allow default lighting
        gameView.delegate = self // Allow renderer to communicate
    }
    
    func initScene() {
        gameScene = SCNScene() // Assign the scene
        gameView.scene = gameScene // Set the game view's scene
        gameView.isPlaying = true // The scene is playing (not paused)
    }
    
    func initCamera() {
        cameraNode = SCNNode() // Assign camera
        cameraNode.camera = SCNCamera() // Assign a new camera
        cameraNode.position = SCNVector3(5, 12, 10) // Set the position of the camera
        cameraNode.lookAt(SCNVector3(0, 5, 0)) // Look at the specified point
        gameScene.rootNode.addChildNode(cameraNode) // Add the camera to the game scene
    }
    
    
    // MARK: Create the pyramid object
    func createTarget() {
        // Create the pyramid geometry
        let geometry: SCNGeometry = SCNPyramid(width: 1.5, height: 1.5, length: 1.5) // Create the pyramid
        let randomColour = Bool.random() ? UIColor.green : UIColor.red // Generate a random colour
        geometry.materials.first?.diffuse.contents = randomColour // Set the pyramind's colour
        
        // Transform that geometry into a node
        let geometryNode = SCNNode(geometry: geometry) // Set a node to the pyramid's geometry
        geometryNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil) // Create the physics body
        geometryNode.name = randomColour == UIColor.green ? "friend" : "enemy" // Set the name of the object
        gameScene.rootNode.addChildNode(geometryNode) // Add the pyramid to the scene
        
        // Apply a force to that node
        let randomDirectionX = Float.random(in: -1...1) // Random direction for the impulse
        let randomDirectionY = Float.random(in: -1...1)
        let force = SCNVector3(randomDirectionX, 13.5, randomDirectionY) // Force to apply
        geometryNode.physicsBody?.applyForce(force, asImpulse: true) // Apply the impulse
    }
    
    
    // MARK: Renderer function
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Render a new pyramid
        if time > targetCreationTime {
            createTarget() // Create a new pyramid
            targetCreationTime = time + 0.6 // Create one in another 0.6 seconds
        }
        
        // Clean up old objects
        cleanUp()
    }
    
    
    // MARK: Respond to touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Get the touches in the view
        let touch = touches.first!
        let location = touch.location(in: gameView)
        let hitList = gameView.hitTest(location, options: nil)
        
        // Perform operation on the tapped object
        if let hitObject = hitList.first { // Get the top object being touched
            let node = hitObject.node // Create the node from the object
            
            self.gameView.backgroundColor = node.name == "friend" ? UIColor.black : UIColor.red // Change the background colour depending on the colour of the pyramid
            node.disappearWithFade(duration: 0.1) // Make the node gradually disappear
        }
    }
    
    
    // MARK: Clean up old objects
    func cleanUp() {
        for node in gameScene.rootNode.childNodes { // Iterate through all the nodes in the scene
            if node.presentation.position.y < -2 { // The node is too low
                node.disappearWithFade() // Make the node gradually disappear
            }
        }
    }
    
    
    // MARK: Device rotation overrides
    override var shouldAutorotate: Bool { return true }
    override var prefersStatusBarHidden: Bool { return true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

}
