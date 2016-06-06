//
//  GameScene.swift
//  XJCookieCrunch
//
//  Created by JunXie on 14-6-30.
//  Copyright (c) 2014 xiejun. All rights reserved.
//

import SpriteKit

let SCORE_FONT_NAME = "GillSans-BoldItalic"

class GameScene: SKScene {
    var level: Level!
    let TileWidth: CGFloat = 32.0
    let TileHeight: CGFloat = 36.0
    
    var swipeFromColumn: Int?
    var swipeFromRow: Int?
    var swipeHandler: ((Swap) -> ())?
    
    let gameLayer = SKNode()
    let cookiesLayer = SKNode()
    let tilesLayer = SKNode()
    var selectionSprite = SKSpriteNode()
    
    let cropLayer = SKCropNode()
    let maskLayer = SKNode()
    
    let swapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
    let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
    let matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
    let fallingCookieSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
    let addCookieSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
    
    override init(size: CGSize) {
        super.init(size: size)
        
        self.anchorPoint = CGPointMake(0.5, 0.5)
        
        // bg
        let background = SKSpriteNode(imageNamed: "Background")
        addChild(background)
        
        // 
        addChild(gameLayer)
        
        let layerPosition = CGPointMake(-TileWidth * CGFloat(NumColumns) / 2, -TileHeight * CGFloat(NumRows) / 2)
        tilesLayer.position = layerPosition
        gameLayer.addChild(tilesLayer)
        
        gameLayer.addChild(cropLayer)
        
        maskLayer.position = layerPosition
        cropLayer.maskNode = maskLayer
        
        cookiesLayer.position = layerPosition
        cropLayer.addChild(cookiesLayer)
        
        self.swipeFromColumn = nil;
        self.swipeFromRow = nil
        
        // load font
        let label = SKLabelNode(fontNamed: SCORE_FONT_NAME)
        NSLog("%@", label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addSpritesForCookies(cookies: XJSet<Cookie>) {
        for cookie in cookies {
            let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
            
            sprite.position = pointForColumn(cookie.column, row: cookie.row)
            cookiesLayer.addChild(sprite)
            cookie.sprite = sprite
            
            sprite.alpha = 0
            sprite.xScale = 0.5
            sprite.yScale = 0.5
            sprite.runAction(SKAction.sequence([
                SKAction.waitForDuration(0.25, withRange: 0.5),
                SKAction.group([
                    SKAction.fadeInWithDuration(0.25),
                    SKAction.scaleTo(1.0, duration: 0.25)
                    ])
                ]))
        }
    }
    
    func removeAllCookieSprites() {
        cookiesLayer.removeAllChildren()
    }
    
    func addTiles() {
        for row in 0..<NumRows {
            for column in 0..<NumColumns {
                // masks
                if level.tileAtColumn(column, row: row) != nil {
                    let tileNode = SKSpriteNode(imageNamed: "MaskTile")
                    tileNode.position = pointForColumn(column, row: row)
                    maskLayer.addChild(tileNode)
                }
            }
        }
        for row in 0...NumRows {
            for column in 0...NumColumns {
                // tiles
                let topLeft = ((column > 0) && (row < NumRows) && level.tileAtColumn(column - 1, row: row) != nil)
                let bottomLeft = ((column > 0) && (row > 0) && level.tileAtColumn(column - 1, row: row - 1) != nil)
                let topRight = ((column < NumColumns) && (row < NumRows) && level.tileAtColumn(column, row: row) != nil)
                let bottomRight = ((column < NumColumns) && (row > 0) && level.tileAtColumn(column, row: row - 1) != nil)
                
                // The tiles are named from 0 to 15, according to the bitmask that is
                // made by comining these four values.
                let value = Int(topLeft) | Int(topRight) << 1 | Int(bottomLeft) << 2 | Int(bottomRight) << 3
                
                // values 0 (no tiles), 6 and 9 (two opposite tiles) are not drawn
                if value != 0 && value != 6 && value != 9 {
                    let name = String(format: "Tile_%ld", value)
                    let tileNode = SKSpriteNode(imageNamed: name)
                    var point = pointForColumn(column, row: row)
                    point.x -= TileWidth / 2
                    point.y -= TileHeight / 2
                    tileNode.position = point
                    tilesLayer.addChild(tileNode)
                }
            }
        }
    }
    
    func pointForColumn(column: Int, row: Int) -> CGPoint {
        return CGPointMake(CGFloat(column) * TileWidth + TileWidth / 2, CGFloat(row) * TileHeight + TileHeight / 2)
    }
    
    func convertPoint(point: CGPoint) -> (success: Bool, column: Int, row: Int) {
        if point.x >= 0 && point.x < CGFloat(NumColumns) * TileWidth && point.y >= 0 && point.y < CGFloat(NumRows) * TileHeight {
            return (true, Int(point.x / TileWidth), Int(point.y / TileHeight))
        } else {
            return (false, 0, 0) // Invalid location
        }
    }
    
    func trySwapHorizontal(horzDelta: Int, vertical vertDelta: Int) {
        // 1
        let toColumn = swipeFromColumn! + horzDelta
        let toRow = swipeFromRow! + vertDelta
        // 2
        if toColumn < 0 || toColumn >= NumColumns { return }
        if toRow < 0 || toRow >= NumRows { return }
        // 3
        if let toCookie = level.cookieAtColumn(toColumn, row: toRow) {
            if let fromCookie = level.cookieAtColumn(swipeFromColumn!, row: swipeFromRow!) {
                // 4 
//                println("*** swapping \(fromCookie) with \(toCookie)")
                if let handler = swipeHandler {
                    let swap = Swap(cookieA: fromCookie, cookieB: toCookie)
                    handler(swap)
                }
                
            }
        }
    }
    
    func animateBeginGame(completion: () -> ()) {
        gameLayer.hidden = false
        gameLayer.position = CGPointMake(0, size.height)
        let action = SKAction.moveBy(CGVectorMake(0, -size.height), duration: 0.3)
        action.timingMode = .EaseOut
        gameLayer.runAction(action, completion: completion)
    }
    
    func animateGameOver(completion: () -> ()) {
        let action = SKAction.moveBy(CGVectorMake(0, -size.height), duration: 0.3)
        action.timingMode = .EaseIn
        gameLayer.runAction(action, completion: completion)
    }
    
    func animateSwap(swap: Swap, completion: () -> ()) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration: NSTimeInterval = 0.3
        
        let moveA = SKAction.moveTo(spriteB.position, duration: duration)
        moveA.timingMode = .EaseOut
        spriteA.runAction(moveA, completion: completion)
        
        let moveB = SKAction.moveTo(spriteA.position, duration: duration)
        moveB.timingMode = .EaseOut
        spriteB.runAction(moveB)
        
        runAction(self.swapSound)
    }
    func animateInvalidSwap(swap: Swap, completion: () -> ()) {
        let spriteA = swap.cookieA.sprite!
        let spriteB = swap.cookieB.sprite!
        
        spriteA.zPosition = 100
        spriteB.zPosition = 90
        
        let duration: NSTimeInterval = 0.2
        
        let moveA = SKAction.moveTo(spriteB.position, duration: duration)
        moveA.timingMode = .EaseOut
        
        let moveB = SKAction.moveTo(spriteA.position, duration: duration)
        moveB.timingMode = .EaseOut
        
        spriteA.runAction(SKAction.sequence([moveA, moveB]), completion: completion)
        spriteB.runAction(SKAction.sequence([moveB, moveA]))
        
        runAction(self.invalidSwapSound)
    }
    
    func animateMathesCookies(chains: XJSet<Chain>, completion: () -> ()) {
        for chain in chains {
            animateScoreForChain(chain)
            
            for cookie in chain.cookies {
                if let sprite = cookie.sprite {
                    if sprite.actionForKey("removing") == nil {
                        let scaleAction = SKAction.scaleTo(0.1, duration: 0.3)
                        scaleAction.timingMode = .EaseOut
                        sprite.runAction(SKAction.sequence([scaleAction, SKAction.removeFromParent()]),
                            withKey:"removing")
                    }
                }
            }
        }
        runAction(self.matchSound)
        runAction(SKAction.waitForDuration(0.3), completion: completion)
    }
    
    func animateFallingCookies(columns: Array<Array<Cookie>>, completion: () -> ()) {
        // 1
        var longestDuration: NSTimeInterval = 0
        for array in columns {
            for (idx, cookie) in array.enumerate() {
                let newPosition = pointForColumn(cookie.column, row: cookie.row)
                // 2
                let delay = 0.05 + 0.15 * NSTimeInterval(idx)
                // 3 
                let sprite = cookie.sprite!
                let duration = NSTimeInterval(((sprite.position.y - newPosition.y) / TileHeight) * 0.1)
                // 4
                longestDuration = max(longestDuration, duration + delay)
                // 5
                let moveAction = SKAction.moveTo(newPosition, duration: duration)
                moveAction.timingMode = .EaseOut
                sprite.runAction(SKAction.sequence([SKAction.waitForDuration(delay), SKAction.group([moveAction, fallingCookieSound])]))
            }
        }
        // 6
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
    func animateNewCookies(columns: Array<Array<Cookie>>, completion: () -> ()) {
        // 1
        var longestDuration: NSTimeInterval = 0
        
        for array in columns {
            // 2
            let startRow = array[0].row + 1
            
            for (idx, cookie) in array.enumerate() {
                // 3
                let sprite = SKSpriteNode(imageNamed: cookie.cookieType.spriteName)
                sprite.position = pointForColumn(cookie.column, row: startRow)
                cookiesLayer.addChild(sprite)
                cookie.sprite = sprite
                // 4
                let delay = 0.1 + 0.2 * NSTimeInterval(array.count - idx - 1)
                // 5
                let duration = NSTimeInterval(startRow - cookie.row) * 0.1
                longestDuration = max(longestDuration, duration + delay)
                // 6
                let newPosition = pointForColumn(cookie.column, row: cookie.row)
                let moveAction = SKAction.moveTo(newPosition, duration: duration)
                moveAction.timingMode = .EaseOut
                sprite.alpha = 0
                sprite.runAction(SKAction.sequence([SKAction.waitForDuration(delay), SKAction.group([SKAction.fadeInWithDuration(0.05), moveAction, self.addCookieSound])]))
            }
        }
        // 7
        runAction(SKAction.waitForDuration(longestDuration), completion: completion)
    }
    
    func animateScoreForChain(chain: Chain) {
        // Figure out what the midpoint of the chain is.
        let firstSprite = chain.firstCookie().sprite!
        let lastSprite = chain.lastCookie().sprite!
        let centerPosition = CGPointMake((firstSprite.position.x + lastSprite.position.x) / 2, (firstSprite.position.y + lastSprite.position.y) / 2 - 8)
        
        // Add a label for the score than slowly floats up.
        let scoreLabel = SKLabelNode(fontNamed: SCORE_FONT_NAME)
        scoreLabel.fontSize = 16
        scoreLabel.text = NSString(format: "%ld", chain.score) as String
        scoreLabel.position = centerPosition
        scoreLabel.zPosition = 300
        cookiesLayer.addChild(scoreLabel)
        
        let moveAction = SKAction.moveBy(CGVectorMake(0, 3), duration: 0.7)
        moveAction.timingMode = .EaseOut
        scoreLabel.runAction(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
    }
    ///
    func showSelectionIndicatorForCookie(cookie: Cookie) {
        selectionSprite.removeFromParent()
        
        if let sprite = cookie.sprite {
            let texture = SKTexture(imageNamed: cookie.cookieType.highlightedSpriteName)
            selectionSprite.size = texture.size()
            if #available(iOS 7.1, *) {
                selectionSprite.runAction(SKAction.setTexture(texture))
            } else {
                // Fallback on earlier versions
            }
            
            sprite.addChild(selectionSprite)
            selectionSprite.alpha = 1.0
        }
    }
    
    func hideSelectionIndicator() {
        selectionSprite.runAction(SKAction.sequence([
            SKAction.fadeOutWithDuration(0.3),
            SKAction.removeFromParent()
            ]))
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // 1
        if  let touch = touches.first {
            let location = touch.locationInNode(cookiesLayer)
            // 2
            let (success, column, row) = convertPoint(location)
            if success {
                // 3
                if let cookie = level.cookieAtColumn(column, row: row) {
                    // 4
                    swipeFromColumn = cookie.column
                    swipeFromRow = cookie.row
                    
                    showSelectionIndicatorForCookie(cookie)
                }
            }
        }
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // 1
        if swipeFromColumn == nil {
            return
        }
        
        // 2 
        if let touch = touches.first {
            let location = touch.locationInNode(cookiesLayer)
            
            let (success, column, row) = convertPoint(location)
            if success {
                
                // 3
                var horzDelta = 0, vertDelta = 0
                if column < swipeFromColumn! { // left
                    horzDelta = -1
                } else if column > swipeFromColumn! { // right
                    horzDelta = 1
                } else if row < swipeFromRow! { // down
                    vertDelta = -1
                } else if row > swipeFromRow! { // up
                    vertDelta = 1
                }
                
                // 4
                if horzDelta != 0 || vertDelta != 0 {
                    trySwapHorizontal(horzDelta, vertical: vertDelta)
                    
                    hideSelectionIndicator()
                    
                    swipeFromColumn = nil
                }
            }
        }
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if selectionSprite.parent != nil && swipeFromColumn != nil {
            hideSelectionIndicator()
        }
        swipeFromColumn = nil
        swipeFromRow = nil
    }
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        if let ts = touches {
            touchesEnded(ts, withEvent: event)
        }
    }
}
