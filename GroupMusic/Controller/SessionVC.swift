//
//  SessionVC.swift
//  GroupMusic
//
//  Created by Noah Schairer on 4/18/18.
//  Copyright © 2018 nschairer. All rights reserved.
//

import UIKit
import Alamofire
import AVFoundation
class SessionVC: UIViewController ,SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate{

    
    
    @IBOutlet weak var songProgressView: UIProgressView!
    @IBOutlet weak var toGolbl: UILabel!
    @IBOutlet weak var completedLbl: UILabel!
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var playlistNameLbl: UILabel!
    @IBOutlet weak var ownerLbl: UILabel!
    
    @IBOutlet weak var trackName: UILabel!
    
    @IBOutlet weak var artistNameLbl: UILabel!
    @IBOutlet weak var pausePlayButton: UIButton!
    
    
    @IBOutlet weak var songOneBtn: UIButton!
    @IBOutlet weak var songOneLbl: UILabel!
    @IBOutlet weak var songTwoBtn: UIButton!
    @IBOutlet weak var songTwoLbl: UILabel!
    @IBOutlet weak var songThreeBtn: UIButton!
    @IBOutlet weak var songThreeLbl: UILabel!
    
    var songArray = [Int:Int]()
    var oneIndex: Int!
    var twoIndex: Int!
    var threeIndex: Int!
    var voteDictionary = [UILabel: String]()

    
    var playListName: String!
    var track: String!
    var artistName: String!
    var owner: String!
    var playlistId: String!
    var userId: String!
    
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var player: SPTAudioStreamingController?
    
    var trackArray = [Track]()
    
    var playpause = false
    var startSong = false
    var startingIndex = 0
    
    var songDictionary = [UIButton: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateAfterFirstLogin()
        bgView.layer.cornerRadius = 20
        print(userId + " " + playlistId)
        
        // Do any additional setup after loading the view.
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }

    @IBAction func pausePlay(_ sender: Any) {
        if startSong == false {
            playSong()
            startSong = true
        }
        if playpause == false {
            
            pausePlayButton.setImage(#imageLiteral(resourceName: "icons8-pause-50"), for: .normal)
            playpause = true
            self.player?.setIsPlaying(true, callback: nil)
        } else {
            pausePlayButton.setImage(#imageLiteral(resourceName: "icons8-play-50"), for: .normal)
            playpause = false
            self.player?.setIsPlaying(false, callback: nil)
        }
    }
    
    var didVote = false
    var vote = 1
    @IBAction func songOneVote(_ sender: Any) {
        if didVote {
            
        } else {
            //songOneLbl.text = "\(vote)"
            DataService.instance.postVotes(sessionId: userId + playlistId, songNumber: "songOne")
            //songArray = [Int(songOneLbl.text!)!:oneIndex,Int(songTwoLbl.text!)!:twoIndex,Int(songThreeLbl.text!)!:threeIndex]
            didVote = true
        }
    }
    
    @IBAction func songTwoVote(_ sender: Any) {
        if didVote {
            
        } else {
            DataService.instance.postVotes(sessionId: userId + playlistId, songNumber: "songTwo")

            didVote = true
        }
    }
    
    
    @IBAction func songThreeVote(_ sender: Any) {
        if didVote {
            
        } else {
            DataService.instance.postVotes(sessionId: userId + playlistId, songNumber: "songThree")

            didVote = true
        }
    }
    
    
    @IBAction func backBtn(_ sender: Any) {
        player?.setIsPlaying(false, callback: { (done) in
            try! self.player?.stop()
        })
        self.dismiss(animated: true, completion: nil)
        
    }
    
    
    func playSong() {
        for obj in trackArray {
            if obj.name == trackName.text {
                self.player?.playSpotifyURI(obj.id, startingWith: 0, startingWithPosition: 0, callback: { (error) in
                    if (error != nil) {
                        print("playing!")
                    } else {
                        print(error ?? "ERROR")
                    }
                })
            }
        }
    }
    
    @objc func updateAfterFirstLogin () {
        voteDictionary = [songOneLbl:"songOne",songTwoLbl:"songTwo",songThreeLbl:"songThree"]
        songDictionary = [songOneBtn:"songOne",songTwoBtn:"songTwo",songThreeBtn:"songThree"]
        if let sessionObj:AnyObject = UserDefaults.standard.value(forKey: "SpotifySession") as AnyObject? {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            self.session = firstTimeSession
            initializePlayer(authSession: session)
            downloadPlaylistTracks(uid: userId, pid: playlistId, finishedDownload: {(done) in
                if done {
                    let random = Int(arc4random_uniform(UInt32(self.trackArray.count)))
                    self.updateUI(index: random)
                    let (one,two,three) = self.threeRandomSongs(count: self.trackArray.count)
                    
                    DataService.instance.uploadTracks(sessionID: self.userId+self.playlistId, songOne: self.trackArray[one], songTwo: self.trackArray[two], songThree: self.trackArray[three], currentSong: self.trackArray[random], completion: {(isdone) in
                        if isdone {
                            for obj in self.songDictionary {
                                DataService.instance.getInitialTracks(songNumber: obj.value, sessionID: self.userId+self.playlistId, completion: { (returnedTrack) in
                                    obj.key.setTitle(returnedTrack.name, for: .normal)
                                })
                            }
                            for vote in self.voteDictionary {
                                DataService.instance.observeForVotes(sessionId: self.userId+self.playlistId, songNumber: vote.value, completion: { (votes) in
                                    vote.key.text = "\(votes)"
                                })
                            }
                        }
                        
                    })
                    
                    
                } else {
                    print("error Downloading")
                }
            })
        }
    }
    func initializePlayer(authSession:SPTSession){
        if self.player == nil {//was nil {
                self.player = SPTAudioStreamingController.sharedInstance()
                self.player!.playbackDelegate = self
                self.player!.delegate = self
                try! player!.start(withClientId: auth.clientID)
                self.player!.login(withAccessToken: authSession.accessToken)
        }
    }
    func updateUI(index: Int) {
        if playListName != nil && playlistId != nil && owner != nil {
            self.playlistNameLbl.text = playListName
            self.ownerLbl.text = owner
            self.artistNameLbl.text = trackArray[index].artist
            self.trackName.text = trackArray[index].name

        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func threeRandomSongs(count: Int) -> (Int,Int,Int) {
        var done = true
        var one = 0
        var two = 0
        var three = 0
        while done {
            one = Int(arc4random_uniform(UInt32(count)))
            two = Int(arc4random_uniform(UInt32(count)))
            three = Int(arc4random_uniform(UInt32(count)))
            if count > 2 && one != two && one != three && two != three {
                done = false
                oneIndex = one
                twoIndex = two
                threeIndex = three
                //print(one,two,three)
                return (one,two,three)
            }
            if count <= 2 {
                return (1, 0, 1)
            }
        }
    }
    
    func downloadPlaylistTracks(uid: String, pid: String, finishedDownload: @escaping (Bool) -> Void) {
        
        var pTrack: Track!
        var tName: String!
        var tArtist: String!
        var tDur: Int!
        var tId: String!
        let url = "https://api.spotify.com/v1/users/\(uid)/playlists/\(pid)/tracks"
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization": "Bearer " + session.accessToken!]).responseJSON { (response) in
            guard let json = response.result.value as? [String: Any] else{return}
            //print(json)
            if let items = json["items"] as? [Dictionary<String, AnyObject>] {
                for obj in items {
                    if let track = obj["track"] as? Dictionary<String, AnyObject> {
                        tDur = track["duration_ms"] as! Int
                        tName = track["name"] as! String
                        tId = track["uri"] as! String
                        if let artist = track["artists"] as? [Dictionary<String,AnyObject>] {
                             tArtist = artist[0]["name"] as! String
                            pTrack = Track(name: tName, artist: tArtist, id: tId, duration: tDur)
                            self.trackArray.append(pTrack)
                            //print(self.trackArray)
                            
                        }
                    }
                }
                finishedDownload(true)
            }

        }
    }
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        print("Logged into player")
    }
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        var minutes: Double!
        for obj in trackArray {
            if obj.name == trackName.text {
                minutes = Double(obj.duration) / 1000
                let (m,s) = secondsToMinutesSeconds(seconds: Int(position))
                let (cm,sm) = secondsToMinutesSeconds(seconds: Int(minutes - position))
                toGolbl.text = "\(cm):\(sm)"
                completedLbl.text = "\(m):\(s)"
                let fractionalProgresss =  Float(position) / (Float(obj.duration) / 1000)
                songProgressView.setProgress(fractionalProgresss, animated: true)
            }
        }
    }
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        if isPlaying {
            self.activateAudioSession()
        } else {
            //self.deactivateAudioSession()
        }
    }
    
    func activateAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    func secondsToMinutesSeconds(seconds: Int) -> (Int,Int) {
        return ((seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        //next song
        didVote = false
        
        DataService.instance.updateStatus(sessionID: userId + playlistId, completion: {(isdone) in
            if isdone {
                    self.nextSong()
            }
        })
    }
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: String!) {
       //get song uri
    }
    func saveData(completion: () -> Void){
    let sArray = ["songOne","songTwo","songThree"]
        for song in sArray {
            DataService.instance.saveSongPopularity(songNumbers: song, sessionId: self.userId + self.playlistId)
        }
        completion()
    }

    func nextSong() {
        let index = greatestVote()
        self.player?.playSpotifyURI(trackArray[index].id, startingWith: 0, startingWithPosition: 0, callback: { (error) in
            if (error != nil) {
                print("playing!")
                self.updateUI(index: index)
            } else {
                print(error ?? "ERROR")
                let (one,two,three) = self.threeRandomSongs(count: self.trackArray.count)
                
                DataService.instance.uploadTracks(sessionID: self.userId+self.playlistId, songOne: self.trackArray[one], songTwo: self.trackArray[two], songThree: self.trackArray[three], currentSong: self.trackArray[index], completion: {(isdone) in
                    if isdone {
                        for obj in self.songDictionary {
                            DataService.instance.getInitialTracks(songNumber: obj.value, sessionID: self.userId+self.playlistId, completion: { (returnedTrack) in
                                obj.key.setTitle(returnedTrack.name, for: .normal)
                            })
                        }
                        self.updateUI(index: index)

                    }
                })
            }
        })
        
    }
    func getTrackIndex(from: [Track], track: Track) -> Int? {
        return from.index(where: {$0 === track})
    }
    
    func greatestVote()->(Int) {
        if Int(songOneLbl.text!)! > Int(songTwoLbl.text!)! && Int(songOneLbl.text!)! > Int(songThreeLbl.text!)! {
            print("Chose song 1")
            self.songOneLbl.text = "0"
            self.songTwoLbl.text = "0"
            self.songThreeLbl.text = "0"
            return oneIndex
        } else if Int(songTwoLbl.text!)! > Int(songOneLbl.text!)! && Int(songTwoLbl.text!)! > Int(songThreeLbl.text!)! {
            print("Chose song 2")
            self.songOneLbl.text = "0"
            self.songTwoLbl.text = "0"
            self.songThreeLbl.text = "0"
            return twoIndex
        } else if Int(songThreeLbl.text!)! > Int(songOneLbl.text!)! && Int(songThreeLbl.text!)! > Int(songTwoLbl.text!)! {
            print("Chose song 3")
            self.songOneLbl.text = "0"
            self.songTwoLbl.text = "0"
            self.songThreeLbl.text = "0"
            return threeIndex
        } else {
            print("it was a tie, selecting random song")
            self.songOneLbl.text = "0"
            self.songTwoLbl.text = "0"
            self.songThreeLbl.text = "0"
            return Int(arc4random_uniform(UInt32(self.trackArray.count)))
        }
    }
}
