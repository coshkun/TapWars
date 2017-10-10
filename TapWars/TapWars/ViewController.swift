//
//  ViewController.swift
//  TapWars
//
//  Created by coskun on 6.10.2017.
//  Copyright © 2017 coskun. All rights reserved.
//

import UIKit
import AudioToolbox

class ViewController: UIViewController {
    
    @IBOutlet weak var greenView: UIView!
    @IBOutlet weak var redView: UIView!
    @IBOutlet weak var greenScoreLabel: UILabel!
    @IBOutlet weak var redScoreLabel: UILabel!
    @IBOutlet weak var cooldownLabel: UILabel!
    @IBOutlet weak var greenHeightConst: NSLayoutConstraint!
    @IBOutlet weak var redHeightConst: NSLayoutConstraint!
    @IBOutlet weak var bottomLineConst: NSLayoutConstraint!
    @IBOutlet weak var topLineConst: NSLayoutConstraint!
    
    var idCounter = 0
    lazy var sndID: [SystemSoundID] = {
        var ids = [SystemSoundID]()
        for i in 0 ..< 9 {
            let newID: SystemSoundID = 0
            ids.append(newID)
        }
        return ids
    }()
    
    //match scores
    var topScore = 0 {
        didSet {
            greenScoreLabel.text = "\(topScore)"
        }
    }
    
    var bottomScore = 0 {
        didSet {
            redScoreLabel.text = "\(bottomScore)"
        }
    }
    
    let maxScore = 20
    var gameOn = false
    var padding: CGFloat = 70 {
        didSet {
            guard view != nil else { return }
            topLineConst.constant = padding
            bottomLineConst.constant = padding
        }
    }
    
    var score = 0 {
        didSet {
            guard let viewHeight = view?.frame.height else {
                return
            }
            let availableSpace: CGFloat = viewHeight - 2 * padding
            
            greenHeightConst.constant =
            max(min(viewHeight, CGFloat(score) / CGFloat(maxScore) * availableSpace + padding), 0)
            
            redHeightConst.constant =
            max(min(viewHeight, CGFloat(maxScore - score) / CGFloat(maxScore) * availableSpace + padding), 0)
            
            UIView.animateWithDuration(0.1,
                delay: 0,
                options: UIViewAnimationOptions.AllowUserInteraction,
                animations: {
                    self.view.layoutIfNeeded()
                },
                completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        padding = 70
        
        //set player2 orientation
        let rotate = CGAffineTransformMakeRotation(CGFloat(M_PI))
        self.greenScoreLabel.transform = rotate
        
        //reset scores
        topScore = 0
        bottomScore = 0
        
        //load the sounds
        loadSoundEffects("counter1.caf")    // id 0
        loadSoundEffects("counter2.caf")    // id 1
        loadSoundEffects("saber_start.caf") // id 2
        loadSoundEffects("saber_end.caf")   // id 3
        loadSoundEffects("clash01.caf")     // id 4
        loadSoundEffects("clash02.caf")     // id 5
        loadSoundEffects("clash03.caf")     // id 6
        loadSoundEffects("clash04.caf")     // id 7
        loadSoundEffects("clash05.caf")     // id 8
        
        //start a new game
        newGame()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func newGame() {
        //reset scores
        score = maxScore / 2
        
        //show scores and fadeout
        greenScoreLabel.alpha = 1
        redScoreLabel.alpha = 1
        UIView.animateWithDuration(2, animations: {
            self.greenScoreLabel.alpha = 0
            self.redScoreLabel.alpha = 0
        })
        
        //cooldown counter
        let stepTime: NSTimeInterval = 1.0
        self.cooldownLabel.alpha = 1
        self.cooldownLabel.text = "3"
        self.playSound(self.sndID[0])
        UIView.animateWithDuration(stepTime,
            animations: {
                self.cooldownLabel.alpha = 0
            }, completion: { _ in
                self.cooldownLabel.text = "2"
                self.cooldownLabel.alpha = 1
                self.playSound(self.sndID[0])
                
                UIView.animateWithDuration(stepTime,
                    animations: {
                        self.cooldownLabel.alpha = 0
                    }, completion: { _ in
                        self.cooldownLabel.text = "1"
                        self.cooldownLabel.alpha = 1
                        self.playSound(self.sndID[0])
                        
                        UIView.animateWithDuration(stepTime,
                            animations: {
                                self.cooldownLabel.alpha = 0
                            }, completion: { _ in
                                self.cooldownLabel.text = "GO"
                                self.cooldownLabel.alpha = 1
                                self.playSound(self.sndID[1])
                                
                                UIView.animateWithDuration(stepTime,
                                    animations: {
                                        self.cooldownLabel.alpha = 0
                                    }, completion: { _ in
                                        self.gameOn = true
                                        self.playSound(self.sndID[2])
                                })
                        })
                })
        })
    }
    
    @IBAction func didTapView(gestureRecognizer: UITapGestureRecognizer) {
        guard let sender = gestureRecognizer.view else {
            print("No view selected!")
            return
        }
        //ignore unles gameon
        guard gameOn else { return }
        
        if sender.tag == 0 {
            score += 1
        } else {
            score -= 1
        }
        
        //play clash sound
        self.playSound(sndID[getRandomClash()])
        
        //check if Green wins
        if score > maxScore {
            //print("Light Side wins.")
            topScore += 1
            gameOn = false
            newGame()
        }
        //check if Red wins
        if score < 0 {
            //print("Dark Side wins.")
            bottomScore += 1
            gameOn = false
            newGame()
        }
    }
    
    //MARK: - Destroyer
    deinit {
        unloadSoundEffects()
    }
    
    //MARK: - Sound FX Functions
    func loadSoundEffects(name: String) {
        var id = sndID[idCounter]
        if let path = NSBundle.mainBundle().pathForResource(name, ofType: nil) {
            let fileURL = NSURL(fileURLWithPath: path, isDirectory: false)
            let error = AudioServicesCreateSystemSoundID(fileURL as CFURL, &id)
            
            if error != kAudioServicesNoError {
                print("Error code \(error) loading sound at path: \(path)")
            } else {
                sndID[idCounter] = id
                idCounter += 1
            }
        }
    }
    
    func playSound(soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
    
    func unloadSoundEffects(){
        for i in 0 ..< sndID.count {
            AudioServicesDisposeSystemSoundID(sndID[i])
            sndID[i] = 0
        }
        idCounter = 0
    }
    
    func getRandomClash() -> Int {
        let diceRoll = Int(arc4random_uniform(UInt32(5)))
        //print(diceRoll)
        return 4 + diceRoll
    }
}










