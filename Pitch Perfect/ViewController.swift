//
//  ViewController.swift
//  Pitch Perfect
//
//  Created by Shailesh Aher on 11/12/17.
//  Copyright © 2017 Shailesh Aher. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var microPhoneButton: UIButton!
    
    @IBOutlet weak var buttonView: UIView!
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    var lengthOfAudio = 0
    var isRecording = false
    
    let audioSession = AVAudioSession.sharedInstance()
    var audioRecorder : AVAudioRecorder?
    var filePath : URL?
    var timer : Timer?
    
    //MARK:- View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButton()
        self.navigationItem.title = "Record Audio"
    }

    override func viewWillAppear(_ animated: Bool) {
        lengthOfAudio = 0
        statusLabel.text = ""
        timerLabel.text = ""
    }
    
    private func setupButton() {
        microPhoneButton.layer.cornerRadius = microPhoneButton.frame.size.width / 2
        microPhoneButton.layer.shadowRadius = microPhoneButton.frame.size.width / 2
        microPhoneButton.layer.shadowColor = UIColor.gray.cgColor
        microPhoneButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        microPhoneButton.layer.shadowOpacity = 0.5
        microPhoneButton.layer.masksToBounds = false
        microPhoneButton.backgroundColor = UIColor(rgb: 0x795548)
        microPhoneButton.tintColor = UIColor.clear
    }
    
    @IBAction func microPhoneButtonTapped(_ sender: Any) {
        isRecording = !isRecording
        microPhoneButton.isSelected = isRecording
        isRecording ? recordAudio() : stopRecording()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return !isRecording
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let controller = segue.destination as? SoundPlayerViewController {
            controller.recordedAudioURL = filePath
        }
    }
}

//MARK:- Functionality
extension ViewController {
    
    private func recordAudio() {
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let recordName = "recordName.wav"
        let path = dirPath.joined(separator: "/") + "/\(recordName)"
        filePath = URL(fileURLWithPath: path)
        
        try! audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .defaultToSpeaker)
        
        audioRecorder = try! AVAudioRecorder(url: filePath!, settings: [:])
        audioRecorder?.isMeteringEnabled  = true
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.updateStatus), userInfo: nil, repeats: true)
    }
    
    private func stopRecording() {
        timer?.invalidate()
        audioRecorder?.stop()
        try! audioSession.setActive(false)
    }
    
    @objc private func updateStatus() {
        lengthOfAudio += 1
        let dotCount = lengthOfAudio % 4
        let dots = [String](repeating: " .", count: dotCount)
        statusLabel.text = "Recording" + dots.joined()
        timerLabel.text = String(lengthOfAudio)
    }
}
