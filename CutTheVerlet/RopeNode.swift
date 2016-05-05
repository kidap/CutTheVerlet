//
//  RopeNode.swift
//  CutTheVerlet
//
//  Created by Nick Lockwood on 07/09/2014.
//  Copyright (c) 2014 Nick Lockwood. All rights reserved.
//

import UIKit
import SpriteKit

class RopeNode: SKNode {
  
  private let length: Int
  private let anchorPoint: CGPoint
  private var ropeSegments: [SKNode] = []
  
  init(length: Int, anchorPoint: CGPoint, name: String) {
    self.length = length
    self.anchorPoint = anchorPoint
    
    super.init()
    
    self.name = name
  }
  
  required init?(coder aDecoder: NSCoder) {
    length = aDecoder.decodeIntegerForKey("length")
    anchorPoint = aDecoder.decodeCGPointForKey("anchorPoint")
    
    super.init(coder: aDecoder)
  }
  
  override func encodeWithCoder(aCoder: NSCoder) {
    
    aCoder.encodeInteger(length, forKey: "length")
    aCoder.encodeCGPoint(anchorPoint, forKey: "anchorPoint")
    
    super.encodeWithCoder(aCoder)
  }
  
  func addToScene(scene: SKScene) {
    zPosition = Layer.Rope
    scene.addChild(self)
    
    let ropeHolder = SKSpriteNode(imageNamed:RopeHolderImage)
    ropeHolder.position = anchorPoint
    ropeHolder.zPosition = Layer.Rope
    
    ropeSegments.append(ropeHolder)
    addChild(ropeHolder)
    
    ropeHolder.physicsBody = SKPhysicsBody(circleOfRadius: ropeHolder.size.width / 2)
    ropeHolder.physicsBody?.dynamic = false
    ropeHolder.physicsBody?.categoryBitMask = Category.RopeHolder
    ropeHolder.physicsBody?.collisionBitMask = 0
    ropeHolder.physicsBody?.collisionBitMask = Category.Prize
    
    
    for i in 0..<length{
      let ropeSegment = SKSpriteNode(imageNamed: RopeTextureImage)
      let offset = ropeSegment.size.height * CGFloat(i+1)
      ropeSegment.position = CGPoint(x: anchorPoint.x, y: anchorPoint.y - offset)
      ropeSegment.name = name
      
      ropeSegments.append(ropeSegment)
      addChild(ropeSegment)
      
      ropeSegment.physicsBody = SKPhysicsBody(rectangleOfSize: ropeSegment.size)
      ropeSegment.physicsBody?.categoryBitMask = Category.Rope
      ropeSegment.physicsBody?.collisionBitMask = Category.RopeHolder
      ropeSegment.physicsBody?.contactTestBitMask = Category.Prize
      
      
      let nodeA = ropeSegments[i]
      let nodeB = ropeSegments[i+1]
      let joint = SKPhysicsJointPin.jointWithBodyA(nodeA.physicsBody!, bodyB: nodeB.physicsBody!, anchor: CGPoint(x: CGRectGetMidX(nodeA.frame), y: CGRectGetMidY(nodeA.frame)))
      scene.physicsWorld.addJoint(joint)
      
    }
    
    
    
  }
  
  func attachToPrize(prize: SKSpriteNode) {
    let lastNode = ropeSegments.last!
    lastNode.position  = CGPoint(x: prize.position.x, y: prize.position.y + prize.size.height * 0.1)
    
    let joint = SKPhysicsJointPin.jointWithBodyA(lastNode.physicsBody!, bodyB: prize.physicsBody!, anchor: lastNode.position)
    
    prize.scene?.physicsWorld.addJoint(joint)
    
  }
}



















