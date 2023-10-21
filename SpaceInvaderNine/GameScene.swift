//
//  GameScene.swift
//  SpaceInvaderNine
//
//  Created by Augustin Desaintfucien on 19/10/2023.
//

import SpriteKit

var score = 0

class GameScene: SKScene, SKPhysicsContactDelegate {
    let player = SKSpriteNode(imageNamed: "playerShip")
    let bulletSound = SKAction.playSoundFileNamed("bulletSound.mp3", waitForCompletion: false)
    let explosionSound = SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false)
    
    var scoreLabel = SKLabelNode()
    
    var live = 8
    var liveLabel = SKLabelNode()
    
    var level = 0
    var allowFireBullet = true

    struct PhysicsCategories{
        static let None : UInt32 = 0
        static let Player : UInt32 = 0b1
        static let Bullet : UInt32 = 0b10
        static let Enemy : UInt32 = 0b100
        static let PowerUp: UInt32 = 0b1000
    }
    
    enum gameState{
        case preGame
        case inGame
        case afterGame
    }
    
    var currentGameState = gameState.inGame
    
    func random() -> CGFloat{
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min : CGFloat, max: CGFloat) -> CGFloat{
        return random() * (max - min) + min
    }
    
    func updateScore(){
        score+=1
        scoreLabel.text = "Score: " + String(score)
        
        if score == 10 || score == 20 || score == 50{
            startNewLevel()
        }
    }
    
    func updateLive(){
        live-=1
        liveLabel.text = "Lives: " + String(live)
        if live < 1{
            gameOver()
        }
    }
    
    func addLive(){
        if live < 10{
            live+=1
            liveLabel.text = "Lives: " + String(live)
        }
    }
    
    let gameArea: CGRect
    
    override init(size: CGSize){
        
        let maxAspectRatio: CGFloat = 16.0 / 9.0
        let playableWidth = (size.height / maxAspectRatio) - 400
        let margin = (size.width - playableWidth) / 2
        gameArea = CGRect(x: margin, y: 0, width: playableWidth, height: size.height)
        super.init(size: size)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView){
        
        score = 0
        
        self.physicsWorld.contactDelegate = self
        
        for i in 0...1{
            
            let background = SKSpriteNode(imageNamed: "background")
            background.size = self.size
            background.name = "background"
            background.position = CGPoint(x: self.size.width / 2, y: self.size.height * CGFloat(i))
            background.zPosition = 0
            background.anchorPoint = CGPoint(x:0.5, y:0)
            self.addChild(background)
        }
      
        
        player.setScale(1)
        player.position = CGPoint(x: self.size.width / 2, y: self.size.height * 0.1)
        player.zPosition = 2
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody!.affectedByGravity = false
        player.physicsBody!.categoryBitMask = PhysicsCategories.Player
        player.physicsBody!.collisionBitMask = PhysicsCategories.None
        player.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy
        self.addChild(player)
        
        scoreLabel.text = "Score: " + String(score)
        scoreLabel.fontSize = 70
        scoreLabel.fontColor = SKColor.white
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabel.position = CGPoint(x: self.size.width * 0.2, y: self.size.height * 0.9)
        scoreLabel.zPosition = 100
        self.addChild(scoreLabel)
        
        liveLabel.text = "Lives: " + String(live)
        liveLabel.fontSize = 70
        liveLabel.fontColor = SKColor.white
        liveLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        liveLabel.position = CGPoint(x: self.size.width * 0.65, y: self.size.height * 0.9)
        liveLabel.zPosition = 100
        self.addChild(liveLabel)
        startNewLevel()
    }
    
    var lastUpdateTime: TimeInterval = 0
    var deltaFrameTime: TimeInterval = 0
    var amountToMovePerSecond: CGFloat = 800.0
    
    func moveBackground(currentTime: TimeInterval){
        
        if lastUpdateTime == 0{
            lastUpdateTime = currentTime
        }else{
            deltaFrameTime = currentTime - lastUpdateTime
            lastUpdateTime = currentTime
        }
        
        let amountToMoveBackground = amountToMovePerSecond * CGFloat(deltaFrameTime)
        
        self.enumerateChildNodes(withName: "background", using: {
            background, stop  in
            
            background.position.y -= amountToMoveBackground
            
            if background.position.y < -self.size.height{
                background.position.y += self.size.height * 2
            }
        })
    }
    
    override func update(_ currentTime: TimeInterval) {
        moveBackground(currentTime: currentTime)
    }
    
    func spawnPowerUp(powerUpSpeed: TimeInterval){
        let randomXStart = random(min: CGRectGetMinX(gameArea), max: CGRectGetMaxX(gameArea))
        let randomXEnd = random(min: CGRectGetMinX(gameArea), max: CGRectGetMaxX(gameArea))
        
        let startPoint = CGPoint(x: randomXStart, y: self.size.height * 1.2)
        let endPoint = CGPoint(x: randomXEnd, y: -self.size.height * 0.2)
        
        let powerUp = SKSpriteNode(imageNamed: "powerUp")
        powerUp.setScale(1)
        powerUp.name = "PowerUp"
        powerUp.position = startPoint
        powerUp.zPosition = 2
        powerUp.physicsBody = SKPhysicsBody(rectangleOf: powerUp.size)
        powerUp.physicsBody!.affectedByGravity = false
        powerUp.physicsBody!.categoryBitMask = PhysicsCategories.PowerUp
        powerUp.physicsBody!.collisionBitMask = PhysicsCategories.None
        powerUp.physicsBody!.contactTestBitMask = PhysicsCategories.Player
        self.addChild(powerUp)
        
        
        let movePowerUp = SKAction.move(to: endPoint, duration: powerUpSpeed)
        let deletePowerUp = SKAction.removeFromParent()

        let powerUpSequence = SKAction.sequence([movePowerUp, deletePowerUp])
        
        if currentGameState == gameState.inGame{
            powerUp.run(powerUpSequence)
        }
    }
    
    
    func spawnEnemy(){
        let randomXStart = random(min: CGRectGetMinX(gameArea), max: CGRectGetMaxX(gameArea))
        let randomXEnd = random(min: CGRectGetMinX(gameArea), max: CGRectGetMaxX(gameArea))
        
        let startPoint = CGPoint(x: randomXStart, y: self.size.height * 1.2)
        let endPoint = CGPoint(x: randomXEnd, y: -self.size.height * 0.2)
        
        let enemy = SKSpriteNode(imageNamed: "enemyShip")
        enemy.setScale(1)
        enemy.name = "Enemy"
        enemy.position = startPoint
        enemy.zPosition = 2
        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody!.affectedByGravity = false
        enemy.physicsBody!.categoryBitMask = PhysicsCategories.Enemy
        enemy.physicsBody!.collisionBitMask = PhysicsCategories.None
        enemy.physicsBody!.contactTestBitMask = PhysicsCategories.Player | PhysicsCategories.Bullet
        self.addChild(enemy)
        
        let moveEnemy = SKAction.move(to: endPoint, duration: 1.2)
        let deleteEnemy = SKAction.removeFromParent()
        let removeOneLive = SKAction.run {
            self.updateLive()
        }
        let enemySequence = SKAction.sequence([moveEnemy, deleteEnemy, removeOneLive])
        
        if currentGameState == gameState.inGame{
            enemy.run(enemySequence)
        }
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let amountToRotate = atan2(dy, dx)
        enemy.zRotation = amountToRotate
    }
    
    func didBegin(_ contact : SKPhysicsContact) {

        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            body1 = contact.bodyA
            body2 = contact.bodyB
        }else{
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        if body1.categoryBitMask == PhysicsCategories.Player && body2.categoryBitMask == PhysicsCategories.Enemy{
            //if the player has hit the enemy
            if body1.node != nil{
                spawnExplosion(spawnPosition: body1.node!.position)
            }
            if body2.node != nil{
                spawnExplosion(spawnPosition: body2.node!.position)
            }
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
            
            gameOver()
        }
        
        if body1.categoryBitMask == PhysicsCategories.Bullet && body2.categoryBitMask == PhysicsCategories.Enemy{
            //if the bullet has hit the enemy
            
            if body2.node != nil{
               if body2.node!.position.y > self.size.height{
                   return
               }else{
                   spawnExplosion(spawnPosition: body2.node!.position)
                   updateScore()
                   self.allowFireBullet = true
               }
            }
            
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
            
        }
        
        if body1.categoryBitMask == PhysicsCategories.Player && body2.categoryBitMask == PhysicsCategories.PowerUp{
            if body1.node != nil{
                print("PowerUp")
                addLive()
                body2.node?.removeFromParent()

            }
        }
        
    }
    
    func spawnExplosion(spawnPosition: CGPoint){
        let explosion = SKSpriteNode(imageNamed: "explosion")
        explosion.position = spawnPosition
        explosion.zPosition = 3
        explosion.setScale(0)
        self.addChild(explosion)
        
        let scaleIn = SKAction.scale(to: 1, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let delete = SKAction.removeFromParent()
        
        let explosionSequence = SKAction.sequence([explosionSound, scaleIn, fadeOut, delete])
        explosion.run(explosionSequence)
    }
    
    func startNewLevel(){
        
        level+=1
        
        if self.action(forKey: "spawnEnemies") != nil{
            self.removeAction(forKey: "spawnEnemies")
        }
        
        var levelDurationEnemy = NSTimeIntervalSince1970
        
        switch level{
        case 1: levelDurationEnemy = 2
        case 2: levelDurationEnemy = 1.7
        case 3: levelDurationEnemy = 1.5
        case 4: levelDurationEnemy = 1.2
        case 5: levelDurationEnemy = 0.9
        default:
            levelDurationEnemy = 0.9
            print("Cannot find level info")
        }
        
        let spawn = SKAction.run(spawnEnemy)
        let waitToSpawn = SKAction.wait(forDuration: levelDurationEnemy)
        let spawnSequence = SKAction.sequence([waitToSpawn, spawn])
        let spawnForEver = SKAction.repeatForever(spawnSequence)
        self.run(spawnForEver)
        
        var levelDurationPowerUp = NSTimeIntervalSince1970
        var powerUpSpeed = NSTimeIntervalSince1970

        switch level{
        case 1: levelDurationPowerUp = 10
        case 2: levelDurationPowerUp = 20
        case 3: levelDurationPowerUp = 30
        case 4: levelDurationPowerUp = 40
        case 5: levelDurationPowerUp = 50
        default:
            levelDurationPowerUp = 50
            print("Cannot find level info")
        }
        
        switch level{
        case 1: powerUpSpeed = 5
        case 2: powerUpSpeed = 3
        case 3: powerUpSpeed = 2
        case 4: powerUpSpeed = 1.5
        case 5: powerUpSpeed = 1
        default:
            powerUpSpeed = 1
            print("Cannot find level info")
        }
        
        let spawnPowerUp = SKAction.run({self.spawnPowerUp(powerUpSpeed: powerUpSpeed)})
        let waitToSpawnPowerUp = SKAction.wait(forDuration: levelDurationPowerUp)
        let spawnPowerUpSequence = SKAction.sequence([waitToSpawnPowerUp, spawnPowerUp])
        let spawnPowerUpForEver = SKAction.repeatForever(spawnPowerUpSequence)
        self.run(spawnPowerUpForEver)
        
    }
    
    
    func startFire(){
        let fire = SKAction.run(fireBullet)
        let waitForFireBullet = SKAction.wait(forDuration: 0.2)
        let fireSequence = SKAction.sequence([fire, waitForFireBullet])
        let fireForEver = SKAction.repeatForever(fireSequence)
        self.run(fireForEver, withKey: "fireForever")
    }
    
    func fireBullet(){
            
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.setScale(1)
        bullet.name = "Bullet"
        bullet.position = player.position
        bullet.zPosition = 1
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody!.affectedByGravity = false
        bullet.physicsBody!.categoryBitMask = PhysicsCategories.Bullet
        bullet.physicsBody!.collisionBitMask = PhysicsCategories.None
        bullet.physicsBody!.contactTestBitMask = PhysicsCategories.Enemy
        
        self.addChild(bullet)
        
        let moveBullet = SKAction.moveTo(y: self.size.height + bullet.size.height, duration: 0.5)
        let deleteBullet = SKAction.removeFromParent()
        
        let bulletSequence = SKAction.sequence([bulletSound, moveBullet, deleteBullet])
        bullet.run(bulletSequence)
    
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentGameState == gameState.inGame{
            startFire()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.action(forKey: "fireForever") != nil{
            self.removeAction(forKey: "fireForever")
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let pointOfTouch = touch.location(in: self)
            let previousPointOfTouch = touch.previousLocation(in: self)
            
            let amountDragged = pointOfTouch.x - previousPointOfTouch.x
            
            if currentGameState == gameState.inGame{
                player.position.x += amountDragged
            }
            
            if player.position.x > gameArea.maxX - player.size.width / 2 {
                player.position.x = gameArea.maxX - player.size.width / 2
            }
            
            if player.position.x < gameArea.minX + player.size.width / 2 {
                player.position.x = gameArea.minX + player.size.width / 2
            }
           
        }
            
    }
    
    func gameOver(){
        currentGameState = gameState.afterGame
        self.removeAllActions()
        self.enumerateChildNodes(withName: "Bullet"){
            bullet, stop in
            bullet.removeAllActions()
        }
        self.enumerateChildNodes(withName: "Enemy"){
            enemy, stop in
            enemy.removeAllActions()
        }
        
        let changeSceneAction = SKAction.run(changeScene)
        let waitToChangeScene = SKAction.wait(forDuration: 1)
        let changeSceneSequence = SKAction.sequence([waitToChangeScene, changeSceneAction])
        self.run(changeSceneSequence)
    }
    
    func changeScene(){
        let sceneToMoveTo = GameOverScene(size: self.size)
        sceneToMoveTo.scaleMode = self.scaleMode
        let changeSceneTransition = SKTransition.fade(withDuration: 0.5)
        self.view!.presentScene(sceneToMoveTo, transition: changeSceneTransition)
    }

}
