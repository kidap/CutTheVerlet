//
//  GameScene.swift
//  CutTheVerlet
//
//  Created by Nick Lockwood on 07/09/2014.
//  Copyright (c) 2014 Nick Lockwood. All rights reserved.
//

import SpriteKit
import AVFoundation



class GameScene: SKScene,SKPhysicsContactDelegate {
  
  private var crocodile:SKSpriteNode!
  private var prize:SKSpriteNode!
  
  override func didMoveToView(view: SKView) {
    
    setUpPhysics()
    setUpScenery()
    setUpPrize()
    setUpRopes()
    setUpCrocodile()
    
    setUpAudio()
  }
  
  //MARK: Level setup
  
  private func setUpPhysics() {
    physicsWorld.contactDelegate = self
    physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
    physicsWorld.speed = 1
    
  }
  
  private func setUpScenery() {
    let background = SKSpriteNode(imageNamed: BackgroundImage)
    background.anchorPoint = CGPoint(x: 0, y: 1)
    background.position = CGPoint(x: 0, y: size.height)
    background.zPosition = Layer.Background
    background.size = CGSize(width: view!.bounds.width, height: view!.bounds.height)
    addChild(background)
    
    let water = SKSpriteNode(imageNamed: WaterImage)
    water.anchorPoint = CGPoint(x: 0, y: 0)
    water.position = CGPoint(x: 0, y: size.height - background.size.height)
    water.zPosition = Layer.Foreground
    water.size = CGSize(width: view!.bounds.width, height: view!.bounds.height * 0.2139)
    addChild(water)
  }
  
  private func setUpPrize() {
    prize = SKSpriteNode(imageNamed:  PrizeImage)
    //prize.position = CGPoint(x: size.width * 0.5, y: size.height * 0.7)
    prize.position = CGPointMake(178.95286560058594, 395.62783813476563)
    prize.zPosition = Layer.Prize
    
    prize.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: PrizeImage), size: prize.size)
    prize.physicsBody?.categoryBitMask = Category.Prize
    prize.physicsBody?.collisionBitMask = 0
    prize.physicsBody?.contactTestBitMask = Category.Rope
    prize.physicsBody?.dynamic = PrizeIsDynamicsOnStart
    
    addChild(prize)
  }
  
  //MARK: Rope methods
  
  private func setUpRopes() {
    let dataFile = NSBundle.mainBundle().pathForResource(RopeDataFile, ofType: nil)
    let ropes = NSArray(contentsOfFile: dataFile!) as! [NSDictionary]
    
    
    for i in 0..<ropes.count{
      let ropeData = ropes[i]
      let length = Int(ropeData["length"] as! NSNumber) * Int(UIScreen.mainScreen().scale)
      let relAnchorPoint = CGPointFromString(ropeData["relAnchorPoint"] as! String)
      let anchorPoint = CGPoint(x: relAnchorPoint.x * view!.bounds.size.width,
                                y: relAnchorPoint.y * view!.bounds.size.height)
      let rope = RopeNode(length: length, anchorPoint: anchorPoint, name: "\(i)")
      
      //Creates rope from multiple segments
      rope.addToScene(self)
      
      //Attaches the last node of the rope to the prize
      rope.attachToPrize(prize)
    }
    
  }
  
  //MARK: Croc methods
  
  private func setUpCrocodile() {
    crocodile = SKSpriteNode(imageNamed: CrocMouthOpenImage)
    
    crocodile.position = CGPoint(x: size.width * 0.75, y: size.height * 0.312)
    crocodile.zPosition = Layer.Crocodile
    
    crocodile.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed:CrocMaskImage), size: crocodile.size)
    crocodile.physicsBody?.categoryBitMask = Category.Crocodile
    crocodile.physicsBody?.collisionBitMask = 0
    crocodile.physicsBody?.contactTestBitMask = Category.Prize
    crocodile.physicsBody?.dynamic = false
    
    addChild(crocodile)
    
    animateCrocodile()
    
  }
  
  private func animateCrocodile() {
    let frames = [ SKTexture(imageNamed: CrocMouthClosedImage),
                   SKTexture(imageNamed: CrocMouthOpenImage)]
    
    let duration = 2.0 + drand48() * 2.0
    
    let move = SKAction.animateWithTextures(frames, timePerFrame: 0.25)
    let wait = SKAction.waitForDuration(duration)
    let rest = SKAction.setTexture(SKTexture(imageNamed: CrocMouthClosedImage))
    let sequence = SKAction.sequence([wait,move,wait,rest])
    
    crocodile.runAction(SKAction.repeatActionForever(sequence))
    
  }
  
  private func runNomNomAnimationWithDelay(delay: NSTimeInterval) {
    
    let openCrocMouth = SKAction.setTexture(SKTexture(imageNamed: CrocMouthOpenImage))
    let wait = SKAction.waitForDuration(delay)
    let closedCrocMouth = SKAction.setTexture(SKTexture(imageNamed: CrocMouthOpenImage))
    let sequence = SKAction.sequence([openCrocMouth,wait,closedCrocMouth])
    
    crocodile.runAction(sequence)
    
  }
  
  //MARK: Touch handling
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    runNomNomAnimationWithDelay(1)
  }
  
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    
    for touch in touches{
    
      let touch = touch as! UITouch
      let startPoint = touch.locationInNode(self)
      let endPoint = touch.previousLocationInNode(self)
      
      scene?.physicsWorld.enumerateBodiesAlongRayStart(startPoint, end: endPoint, usingBlock: { (body, point, normal, stop) in
        //bodi is the entire rope
        self.checkIfRopeCutWithBody(body)
      })
      
      let emitter = SKEmitterNode(fileNamed: "Particle.sks")
      emitter!.position = startPoint
      emitter!.zPosition = Layer.Rope
      addChild(emitter!)
      
    }
    
  }
  
  //MARK: Game logic
  
  override func update(currentTime: CFTimeInterval) {
    if prize.position.y <= 0 {
      let transitions = [
        SKTransition.doorsOpenHorizontalWithDuration(1.0),
        SKTransition.doorsOpenVerticalWithDuration(1.0),
        SKTransition.doorsCloseHorizontalWithDuration(1.0),
        SKTransition.doorsCloseVerticalWithDuration(1.0),
        SKTransition.flipHorizontalWithDuration(1.0),
        SKTransition.flipVerticalWithDuration(1.0),
        SKTransition.moveInWithDirection(.Left, duration:1.0),
        SKTransition.pushWithDirection(.Right, duration:1.0),
        SKTransition.revealWithDirection(.Down, duration:1.0),
        SKTransition.crossFadeWithDuration(1.0),
        SKTransition.fadeWithColor(UIColor.darkGrayColor(), duration:1.0),
        SKTransition.fadeWithDuration(1.0),
        ]
      
      let randomIndex = arc4random_uniform(UInt32(transitions.count))
      switchToNewGameWithTransition(transitions[Int(randomIndex)])
    }
    
  }
  
  func didBeginContact(contact: SKPhysicsContact) {
    if ( contact.bodyA == crocodile.physicsBody && contact.bodyB == prize.physicsBody ) ||
      ( contact.bodyB == crocodile.physicsBody && contact.bodyA == prize.physicsBody ){
      
      
      let shrink = SKAction.scaleBy(0, duration: 0.08)
      let remove = SKAction.removeFromParent()
      let sequence = SKAction.sequence([shrink, remove])
      
      prize.runAction(sequence)
      
      
      let transitions = [
        SKTransition.doorsOpenHorizontalWithDuration(1.0),
        SKTransition.doorsOpenVerticalWithDuration(1.0),
        SKTransition.doorsCloseHorizontalWithDuration(1.0),
        SKTransition.doorsCloseVerticalWithDuration(1.0),
        SKTransition.flipHorizontalWithDuration(1.0),
        SKTransition.flipVerticalWithDuration(1.0),
        SKTransition.moveInWithDirection(.Left, duration:1.0),
        SKTransition.pushWithDirection(.Right, duration:1.0),
        SKTransition.revealWithDirection(.Down, duration:1.0),
        SKTransition.crossFadeWithDuration(1.0),
        SKTransition.fadeWithColor(UIColor.darkGrayColor(), duration:1.0),
        SKTransition.fadeWithDuration(1.0),
        ]
      let randomIndex = arc4random_uniform(UInt32(transitions.count))
      switchToNewGameWithTransition(transitions[Int(randomIndex)])
    }
    
  }
  
  private func checkIfRopeCutWithBody(body: SKPhysicsBody) {
    let node = body.node
    if let name = node!.name{
    
      prize.physicsBody?.dynamic = true
      
      //remove segment cut
      node!.removeFromParent()
      
      //remove the entire rope
      self.enumerateChildNodesWithName(name, usingBlock: { (node, stop) in
        let fadeAway = SKAction.fadeOutWithDuration(0.25)
        let removeNode = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeAway, removeNode])
        
        node.runAction(sequence)
      })
      
      
      
    }
    
  }
  
  private func switchToNewGameWithTransition(transition: SKTransition) {
    let delay = SKAction.waitForDuration(1)
    let transition = SKAction.runBlock {
      let scene = GameScene(size: self.size)
      self.view?.presentScene(scene, transition: transition)
    }
    runAction(SKAction.sequence([delay,transition]))
    
    
  }
  
  //MARK: Audio
  
  private func setUpAudio() {
    
    
  }
}
