//
//  SoundPlayerViewController.swift
//  Pitch Perfect
//
//  Created by Shailesh Aher on 11/13/17.
//  Copyright © 2017 Shailesh Aher. All rights reserved.
//

import UIKit
import AVFoundation

class SoundPlayerViewController: UIViewController {
    
    //MARK: Vars
    var recordedAudioURL    :   URL?
    var audioFile           :   AVAudioFile?
    var audioEngine         :   AVAudioEngine?
    var audioPlayerNode     :   AVAudioPlayerNode?
    var stopTimer           :   Timer?
    
    //MARK: UI-Elements
    @IBOutlet weak var squiralButton: UIButton!
    @IBOutlet weak var anonimusButton: UIButton!
    @IBOutlet weak var parrotButton: UIButton!
    @IBOutlet weak var kangarooButton: UIButton!
    @IBOutlet weak var reverbButton: UIButton!
    @IBOutlet weak var snailButton: UIButton!
    
    var activatedButton : UIButton?
    
    // MARK: Alerts
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
    }

    override func viewDidLoad() {
        setupAudio()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        audioPlayerNode?.stop()
    }

    //MARK: UI Connection
    @IBAction func squiralEffect(_ sender: Any) {
        playSound(pitch: 1000)
    }
    
    @IBAction func anonimusEffect(_ sender: Any) {
        playSound(pitch: -1000)
    }
    
    @IBAction func parrotEffect(_ sender: Any) {
        playSound(rate: 1.5)
    }
    
    @IBAction func kangarooEffect(_ sender: Any) {
        playSound(echo: true)
    }
    
    
    @IBAction func reverbEffect(_ sender: Any) {
        playSound(reverb: true)
    }
    
    @IBAction func snailEffect(_ sender: Any) {
        playSound(rate: 0.5)
    }
    
    
    //MARK: Helper Functions
    private func setButton(status : Bool) {
        squiralButton.isEnabled = status
        anonimusButton.isEnabled = status
        parrotButton.isEnabled = status
        kangarooButton.isEnabled = status
        reverbButton.isEnabled = status
        snailButton.isEnabled = status
    }
    
    private func setupAudio() {
        // initialize (recording) audio file
        do {
            audioFile = try AVAudioFile(forReading: recordedAudioURL!)
        } catch {
            showAlert(Alerts.AudioFileError, message: String(describing: error))
        }
    }
    
    private func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}

//MARK:- Functionality
extension SoundPlayerViewController {
    
    private func playSound(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {
        
        setButton(status: false)
        
        // initialize audio engine components
        audioEngine = AVAudioEngine()
        
        // node for playing audio
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine?.attach(audioPlayerNode!)
        
        // node for adjusting rate/pitch
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changeRatePitchNode.rate = rate
        }
        audioEngine?.attach(changeRatePitchNode)
        
        // node for echo
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine?.attach(echoNode)
        
        // node for reverb
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine?.attach(reverbNode)
        
        // connect nodes
        if echo && reverb {
            connectAudioNodes(audioPlayerNode!, changeRatePitchNode, echoNode, reverbNode, audioEngine!.outputNode)
        } else if echo {
            connectAudioNodes(audioPlayerNode!, changeRatePitchNode, echoNode, audioEngine!.outputNode)
        } else if reverb {
            connectAudioNodes(audioPlayerNode!, changeRatePitchNode, reverbNode, audioEngine!.outputNode)
        } else {
            connectAudioNodes(audioPlayerNode!, changeRatePitchNode, audioEngine!.outputNode)
        }
        
        // schedule to play and start the engine!
        audioPlayerNode?.stop()
        audioPlayerNode?.scheduleFile(audioFile!, at: nil) {
            
            var delayInSeconds: Double = 0
            
            if let lastRenderTime = self.audioPlayerNode?.lastRenderTime, let playerTime = self.audioPlayerNode?.playerTime(forNodeTime: lastRenderTime) {
                
                if let rate = rate {
                    delayInSeconds = Double(self.audioFile!.length - playerTime.sampleTime) / Double(self.audioFile!.processingFormat.sampleRate) / Double(rate)
                } else {
                    delayInSeconds = Double(self.audioFile!.length - playerTime.sampleTime) / Double(self.audioFile!.processingFormat.sampleRate)
                }
            }
            
            // schedule a stop timer for when audio finishes playing
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(SoundPlayerViewController.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main.add(self.stopTimer!, forMode: RunLoopMode.defaultRunLoopMode)
        }
        
        do {
            try audioEngine?.start()
        } catch {
            showAlert(Alerts.AudioEngineError, message: String(describing: error))
            return
        }
        
        // play the recording!
        audioPlayerNode?.play()
    }
    
    @objc private func stopAudio() {
        audioPlayerNode?.stop()
        stopTimer?.invalidate()
        audioEngine?.stop()
        audioEngine?.reset()
        setButton(status: true)
    }
    
    // MARK: Connect List of Audio Nodes
    private func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine?.connect(nodes[x], to: nodes[x+1], format: audioFile!.processingFormat)
        }
    }
}
