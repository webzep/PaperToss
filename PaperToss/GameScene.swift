//
//  GameScene.swift
//  PaperToss
//
//  Created by steve on 10/1/17.
//  Copyright © 2017 Steve Richardson. All rights reserved.
//

import SpriteKit
import GameplayKit

// The current state of the game
enum GameState {
    case playing
    case menu
    static var current = GameState.playing
}

struct pc { // Physics Category
    static let none: UInt32 = 0x1 << 0
    static let ball: UInt32 = 0x1 << 1
    static let lBin: UInt32 = 0x1 << 2
    static let rBin: UInt32 = 0x1 << 3
    static let base: UInt32 = 0x1 << 4
    static let sG: UInt32 = 0x1 << 5
    static let eG: UInt32 = 0x1 << 6
}

// Really these can just be a variable inside the GameScene Class
struct t { // Start and end touch points - Records when we touch the ball (start) & when we let go (end)
    static var start = CGPoint()
    static var end = CGPoint()
}

// Same as these
struct c {  // Constants
    static var grav = CGFloat() // Gravity
    static var yVel = CGFloat() // Initial Y Velocity
    static var airTime = TimeInterval() // Time the ball is in the air
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Variables
    
    var grids = false   // turn on to see all the physics grid lines
    
    // SKSprites
    var bg = SKSpriteNode(imageNamed: "bgImage")            // background image
    var bFront = SKSpriteNode(imageNamed: "binFront")       // Front portion of the bin
    var bBack = SKSpriteNode(imageNamed: "binBack")         // rear portion of the bin
    var pBall = SKSpriteNode(imageNamed: "paperBallImage")  // Paper Ball skin
    
    //SKShapes
    var ball = SKShapeNode()
    var leftWall = SKShapeNode()
    var rightWall = SKShapeNode()
    var base = SKShapeNode()
    var endG = SKShapeNode()    // The ground that the bin will sit on
    var startG = SKShapeNode()  // Where the paper ball will start
    
    // SKLabels
    var windLbl = SKLabelNode()
    
    // CGFloats
    var pi = CGFloat(M_PI)
    var wind = CGFloat()
    
    var touchingBall = false 
    
    // Did Move To View - The GameViewController.swift has now displayed GameScene.swift and will instantly run this function.
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            c.grav = -6
            c.yVel = self.frame.height / 4
            c.airTime = 1.5
        }else{
            // iPad
        }
        
        physicsWorld.gravity = CGVector(dx: 0, dy: c.grav)
        
        setUpGame()
    }
    
    // Fires the instant a touch has made contact with the screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if GameState.current == .playing {
                if ball.contains(location){
                    t.start = location
                    touchingBall = true
                }
            }
        }
    }
    
    // Fires as soon as the touch leaves the screen
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if GameState.current == .playing && !ball.contains(location) && touchingBall{
                t.end = location
                touchingBall = false
                fire()
            }
        }
    }
    
    // Set the images and physics properties of the GameScene
    func setUpGame() {
        GameState.current = .playing
        
        // Background
        let bgScale = CGFloat(bg.frame.width / bg.frame.height) // eg. 1.4 as a scale
        
        bg.size.height = self.frame.height
        bg.size.width = bg.size.height * bgScale
        bg.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        bg.zPosition = 0
        self.addChild(bg)
        
        //Bin front and back
        let binScale = CGFloat(bBack.frame.width / bBack.frame.height)
        
        bBack.size.height = self.frame.height / 9
        bBack.size.width = bBack.size.height * binScale
        bBack.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 3)
        bBack.zPosition = bg.zPosition + 1
        self.addChild(bBack)
        
        bFront.size = bBack.size
        bFront.position = bBack.position
        bFront.zPosition = bBack.zPosition + 3
        self.addChild(bFront)
        
        // Start ground - make grids true at the top to see these lines
        startG = SKShapeNode(rectOf: CGSize(width: self.frame.width, height: 5))
        startG.fillColor = .red
        startG.strokeColor = .clear
        startG.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 10)
        startG.zPosition = 10
        startG.alpha = grids ? 1 : 0
        
        startG.physicsBody = SKPhysicsBody(rectangleOf: startG.frame.size)
        startG.physicsBody?.categoryBitMask = pc.sG
        startG.physicsBody?.collisionBitMask = pc.ball
        startG.physicsBody?.contactTestBitMask = pc.none
        startG.physicsBody?.affectedByGravity = false
        startG.physicsBody?.isDynamic = false
        self.addChild(startG)
        
        // End ground
        endG = SKShapeNode(rectOf: CGSize(width: self.frame.width * 2, height: 5))
        endG.fillColor = .red
        endG.strokeColor = .clear
        endG.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 3 - bFront.frame.height / 2)
        endG.zPosition = 10
        endG.alpha = grids ? 1 : 0
        
        endG.physicsBody = SKPhysicsBody(rectangleOf: endG.frame.size)
        endG.physicsBody?.categoryBitMask = pc.eG
        endG.physicsBody?.collisionBitMask = pc.ball
        endG.physicsBody?.contactTestBitMask = pc.none
        endG.physicsBody?.affectedByGravity = false
        endG.physicsBody?.isDynamic = false
        self.addChild(endG)
        
        // Left Wall of the bin
        leftWall = SKShapeNode(rectOf: CGSize(width: 3, height: bFront.frame.height / 1.6))
        leftWall.fillColor = .red
        leftWall.strokeColor = .clear
        leftWall.position = CGPoint(x: bFront.position.x - bFront.frame.width / 2.5, y: bFront.position.y)
        leftWall.zPosition = 10
        leftWall.alpha = grids ? 1 : 0
        
        leftWall.physicsBody = SKPhysicsBody(rectangleOf: leftWall.frame.size)
        leftWall.physicsBody?.categoryBitMask = pc.lBin
        leftWall.physicsBody?.collisionBitMask = pc.ball
        leftWall.physicsBody?.contactTestBitMask = pc.none
        leftWall.physicsBody?.affectedByGravity = false
        leftWall.physicsBody?.isDynamic = false
        leftWall.zRotation = pi / 25
        self.addChild(leftWall)
        
        // Right wall of the bin
        rightWall = SKShapeNode(rectOf: CGSize(width: 3, height: bFront.frame.height / 1.6))
        rightWall.fillColor = .red
        rightWall.strokeColor = .clear
        rightWall.position = CGPoint(x: bFront.position.x + bFront.frame.width / 2.5, y: bFront.position.y)
        rightWall.zPosition = 10
        rightWall.alpha = grids ? 1 : 0
        
        rightWall.physicsBody = SKPhysicsBody(rectangleOf: rightWall.frame.size)
        rightWall.physicsBody?.categoryBitMask = pc.rBin
        rightWall.physicsBody?.collisionBitMask = pc.ball
        rightWall.physicsBody?.contactTestBitMask = pc.none
        rightWall.physicsBody?.affectedByGravity = false
        rightWall.physicsBody?.isDynamic = false
        rightWall.zRotation = -pi / 25
        self.addChild(rightWall)
        
        // The base of the bin
        base = SKShapeNode(rectOf: CGSize(width: bFront.frame.width / 2, height: 3))
        base.fillColor = .red
        base.strokeColor = .clear
        base.position = CGPoint(x: bFront.position.x, y: bFront.position.y - bFront.frame.height / 4)
        base.zPosition = 10
        base.alpha = grids ? 1 : 0
        base.physicsBody = SKPhysicsBody(rectangleOf: base.frame.size)
        base.physicsBody?.categoryBitMask = pc.base
        base.physicsBody?.collisionBitMask = pc.ball
        base.physicsBody?.contactTestBitMask = pc.ball
        base.physicsBody?.affectedByGravity = false
        base.physicsBody?.isDynamic = false
        self.addChild(base)
        
        // The wind label
        windLbl.text = "Wind = 0"
        windLbl.position = CGPoint(x: self.frame.width / 2, y: self.frame.height * 4 / 5)
        windLbl.fontSize = self.frame.width / 10
        windLbl.zPosition = bg.zPosition + 1
        self.addChild(windLbl)
        
        // Get new wind and setup the ball
        setWind()
        setBall()
    }
    
    // Set up the ball. This will be called to reset the ball too
    func setBall() {
        
        // Remove and reset incase the ball was previously thrown
        pBall.removeFromParent()
        ball.removeFromParent()
        
        ball.setScale(1)
        
        // Set up ball
        ball = SKShapeNode(circleOfRadius: bFront.frame.width / 1.5)
        ball.fillColor = grids ? .blue : .clear
        ball.strokeColor = .clear
        ball.position = CGPoint(x: self.frame.width / 2, y: startG.position.y + ball.frame.height)
        ball.zPosition = 10
        
        // Add "paper skin" to the circle shape
        pBall.size = ball.frame.size
        ball.addChild(pBall)
        
        // Set up the balls physics properties
        ball.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: "paperBallImage"), size: pBall.size)
        ball.physicsBody?.categoryBitMask = pc.ball
        ball.physicsBody?.collisionBitMask = pc.sG
        ball.physicsBody?.contactTestBitMask = pc.base
        ball.physicsBody?.affectedByGravity = true
        ball.physicsBody?.isDynamic = true
        self.addChild(ball)
    }
    
    // Fetch a new wind speed and store it for use on the ball
    func setWind() {
        let multi = CGFloat(50)
        let rnd = CGFloat(arc4random_uniform(UInt32(10))) - 5
        
        windLbl.text = "Wind: \(rnd)"
        wind = rnd * multi
    }
    
    // When touches ended this is called to shoot the paper ball
    func fire() {
        
        let xChange = t.end.x - t.start.x
        let angle = (atan(xChange / (t.end.y - t.start.y)) * 180 / pi)
        let amendedX = (tan(angle * pi / 180) * c.yVel) * 0.5
        
        // Throw it!
        let throwVec = CGVector(dx: amendedX, dy: c.yVel)
        ball.physicsBody?.applyImpulse(throwVec, at: t.start)
        
        // Shrink
        ball.run(SKAction.scale(by: 0.3, duration: c.airTime))
        
        // Change Collision Bitmask
        let wait = SKAction.wait(forDuration: c.airTime / 2)
        let changeCollision = SKAction.run({
            self.ball.physicsBody?.collisionBitMask = pc.sG | pc.eG | pc.base | pc.lBin | pc.rBin
            self.ball.zPosition = self.bg.zPosition + 2
        })
        
        // ADD WIND STEVE!
        let windWait = SKAction.wait(forDuration: c.airTime / 4)
        let push = SKAction.applyImpulse(CGVector(dx: wind, dy: 0), duration: 1)
        ball.run(SKAction.sequence([windWait, push]))
        self.run(SKAction.sequence([wait,changeCollision]))
        
        // Wait & reset
        let wait4 = SKAction.wait(forDuration: 4)
        let reset = SKAction.run({
            self.setWind()
            self.setBall()
        })
        self.run(SKAction.sequence([wait4,reset]))
    }
}
