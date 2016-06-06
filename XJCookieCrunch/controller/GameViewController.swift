//
//  GameViewController.swift
//  XJCookieCrunch
//
//  Created by JunXie on 14-6-30.
//  Copyright (c) 2014 xiejun. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        
        let path = NSBundle.mainBundle().pathForResource(file as String, ofType: "sks")
        
        let sceneData = try! NSData(contentsOfFile: path!, options: .DataReadingMappedIfSafe)
        let archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
        
        archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
        let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
        archiver.finishDecoding()
        return scene
    }
}

class GameViewController: UIViewController {
    
    var level: Level!
    var scene: GameScene!
    
    var movesLeft: Int = 0
    var score: Int = 0
    
    var backgroundMusic: AVAudioPlayer!
    
    @IBOutlet var targetLabel: UILabel!
    @IBOutlet var movesLabel: UILabel!
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var gameOverPanel: UIImageView!
    @IBOutlet var shuffleButton: UIButton!
    @IBAction func shuffleButtonPressed(sender: UIButton) {
        shuffle()
        decreaseMoves()
    }

    var tapGestureRecognizer: UITapGestureRecognizer!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view.
        let skView = self.view as! SKView
        skView.multipleTouchEnabled = false
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        // Create and configure the scene.
        self.scene = GameScene(size: skView.bounds.size)
        self.scene.scaleMode = SKSceneScaleMode.AspectFill
        
        level = Level(filename: "Level_1")
        scene.level = level
        scene.addTiles()
        scene.swipeHandler = handleSwipe
        
        gameOverPanel.hidden = true
        shuffleButton.hidden = true

        // Present the scene.
        skView.presentScene(self.scene)
        
        // bgm
        let url = NSBundle.mainBundle().URLForResource("Mining by Moonlight", withExtension: "mp3")
        backgroundMusic = try? AVAudioPlayer(contentsOfURL: url!)
        backgroundMusic.numberOfLoops = -1
        backgroundMusic.play()
        
        beginGame()
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.AllButUpsideDown
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    /// Game Logic
    func beginGame() {
        movesLeft = level.maximumMoves
        score = 0
        updateLabel()
        level.resetComboMultiplier()
        
        scene.animateBeginGame() {
            self.shuffleButton.hidden = false
        }
        shuffle()
    }
    
    func showGameOver() {
        gameOverPanel.hidden = false
        scene.userInteractionEnabled = false
        shuffleButton.hidden = true
        
        scene.animateGameOver(){
            self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(GameViewController.hideGameOver))
            self.view.addGestureRecognizer(self.tapGestureRecognizer)
            }
    }
    func hideGameOver() {
        view.removeGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer = nil
        
        gameOverPanel.hidden = true
        scene.userInteractionEnabled = true
        
        beginGame()
    }
    
    func shuffle() {
        let newCookies = level.shuffle()
        scene.removeAllCookieSprites()
        scene.addSpritesForCookies(newCookies)
    }
    
    func handleSwipe(swap: Swap) {
        self.view.userInteractionEnabled = false
        if level.isPossibleSwap(swap) {
            level.performSwap(swap)
            scene.animateSwap(swap, completion: handleMatches)
        } else {
            scene.animateInvalidSwap(swap, completion: {
                self.view.userInteractionEnabled = true
                })
        }
    }
    
    func handleMatches() {
        let chains = level.removeMatches()
        if chains.count == 0 {
            beginNextTurn()
            return
        }
        // TODO: do something with the chains set
        scene.animateMathesCookies(chains, completion: {
            for chain in chains {
                self.score += chain.score
            }
            self.updateLabel()
            let columns = self.level.fillHoles()
            self.scene.animateFallingCookies(columns, completion: {
                let columns = self.level.topUpCookies()
                self.scene.animateNewCookies(columns, completion: {
                    self.handleMatches()
                    })
                })
            })
    }
    
    func beginNextTurn() {
        level.resetComboMultiplier()
        level.detectPossibleSwaps()
        view.userInteractionEnabled = true
        decreaseMoves()
    }
    
    func updateLabel() {
        targetLabel.text = NSString(format: "%ld", level.targetScore) as String
        movesLabel.text = NSString(format: "%ld", movesLeft) as String
        scoreLabel.text = NSString(format: "%ld", score) as String
    }
    
    func decreaseMoves() {
        --movesLeft
        updateLabel()
        
        if score >= level.targetScore {
            gameOverPanel.image = UIImage(named: "LevelComplete")
            showGameOver()
        } else if movesLeft == 0 {
            gameOverPanel.image = UIImage(named: "GameOver")
            showGameOver()
        }
    }
}
