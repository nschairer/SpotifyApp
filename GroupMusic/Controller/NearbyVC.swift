//
//  NearbyVC.swift
//  GroupMusic
//
//  Created by Noah Schairer on 4/27/18.
//  Copyright © 2018 nschairer. All rights reserved.
//

import UIKit

class NearbyVC: UIViewController {
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var playlistName: UILabel!
    @IBOutlet weak var playlistOwner: UILabel!
    @IBOutlet weak var currentTrackName: UILabel!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var songOneBtn: UIButton!
    @IBOutlet weak var songOneLbl: UILabel!
    @IBOutlet weak var songTwoBtn: UIButton!
    @IBOutlet weak var songTwoLbl: UILabel!
    @IBOutlet weak var songThreeBtn: UIButton!
    @IBOutlet weak var songThreeLbl: UILabel!
    
    
    var pName: String!
    var track: String!
    var aName: String!
    var oName: String!
    var pid: String!
    var oid: String!
    var songDictionary = [UIButton: String]()
    var voteDictionary = [UILabel: String]()

    var didVote = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bgView.layer.cornerRadius = 20
        updateUI()
        
        
        
        // Do any additional setup after loading the view.
    }

    @IBAction func dismiss(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func songOneVote(_ sender: Any) {
        if didVote {

        } else{
            didVote = true
        DataService.instance.postVotes(sessionId: oid + pid, songNumber: "songOne")
        }
    }
    
    @IBAction func songTwoVote(_ sender: Any) {
        if didVote {

        } else{
            didVote = true
        DataService.instance.postVotes(sessionId: oid + pid, songNumber: "songTwo")
       }
    }
    
    @IBAction func songThreevote(_ sender: Any) {
        if didVote {

        } else{
            didVote = true
        DataService.instance.postVotes(sessionId: oid + pid, songNumber: "songThree")
        }
    }
    
    func updateUI() {
        DataService.instance.getcurrentSong(sessionId: self.oid+self.pid, completion: { (returnedTrack) in
            self.currentTrackName.text = returnedTrack.name
            self.artistName.text = returnedTrack.artist
        })
        playlistName.text = pName
        playlistOwner.text = oName
        songDictionary = [songOneBtn:"songOne",songTwoBtn:"songTwo",songThreeBtn:"songThree"]
        voteDictionary = [songOneLbl:"songOne",songTwoLbl:"songTwo",songThreeLbl:"songThree"]

        for obj in self.songDictionary {
            DataService.instance.observerForSongChange(songNumber: obj.value, sessionId: self.oid+self.pid, completion: { (returnedTrack) in
                obj.key.setTitle(returnedTrack.name, for: .normal)
            })
        }
        for vote in self.voteDictionary {
            DataService.instance.observeForVotes(sessionId: self.oid+self.pid, songNumber: vote.value, completion: { (votes) in
                vote.key.text = "\(votes)"
                
            })
        }
        DataService.instance.observeStatus(sessionId: oid + pid) { (nextSong) in
            self.didVote = nextSong
        }
    }
    
}
