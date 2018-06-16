//
//  DatabaseService.swift
//  GroupMusic
//
//  Created by Noah Schairer on 4/22/18.
//  Copyright © 2018 nschairer. All rights reserved.
//

import Foundation
import Firebase
import CoreLocation


let DB_BASE = Database.database().reference()

class DataService {
    static let instance = DataService()
    
    private var _REF_BASE = DB_BASE
    private var _REF_USERS = DB_BASE.child("users")
    private var _REF_SESSIONS = DB_BASE.child("sessions")
    private var _REF_SONGS = DB_BASE.child("songs")

    var REF_SONGS: DatabaseReference {
        return _REF_SONGS
    }
    var REF_BASE: DatabaseReference {
        return _REF_BASE
    }
    var REF_USERS: DatabaseReference {
        return _REF_USERS
    }
    var REF_SESSIONS: DatabaseReference {
        return _REF_SESSIONS
    }
    
    func createDBUser(uid: String, userData: Dictionary<String, Any>) {
        REF_USERS.child(uid).updateChildValues(userData)
    }
    func getDBName(uid: String, complete: @escaping (_ name: String) -> ()){
        var name: String!
        REF_USERS.observeSingleEvent(of: .value) { (UserData) in
            guard let userName = UserData.children.allObjects as? [DataSnapshot] else {return}
            for obj in userName {
                if obj.key == uid {
                    name = obj.childSnapshot(forPath: "name").value as? String
                }
            }
            complete(name)
        }
    }
    func createSession(latitude: Double, longitude: Double, status: String, ownerName: String, ownerId: String, playlistId: String, playlistName: String) {
        REF_SESSIONS.child(ownerId + playlistId).updateChildValues(["latitude": latitude,"longitude": longitude, "status": status, "oid": ownerId, "pid":playlistId, "ownerName": ownerName, "pName": playlistName])
    }
    func downloadNearbySessions(currentLocation: CLLocation,userCreationComplete: @escaping (_ status: [Playlist]) -> ()) {
        var nearByArray = [Playlist]()
        REF_SESSIONS.observeSingleEvent(of: .value) { (sessions) in
            guard let allSessions = sessions.children.allObjects as? [DataSnapshot] else {return}
            for obj in allSessions {
                let latitude = obj.childSnapshot(forPath: "latitude").value as? Double
                let longitutde = obj.childSnapshot(forPath: "longitude").value as? Double
                if currentLocation.distance(from: CLLocation(latitude: latitude!, longitude: longitutde!)) <= 100 {
                    //print(obj)
                    let name = obj.childSnapshot(forPath: "ownerName").value as? String
                    let pName = obj.childSnapshot(forPath: "pName").value as? String
                    let oid = obj.childSnapshot(forPath: "oid").value as? String
                    let pid = obj.childSnapshot(forPath: "pid").value as? String
                    let sesh = Playlist(id: pid!, Name: pName!, Owner: name!, uri: "", oid: oid!)
                    nearByArray.append(sesh)
                    
                } else {
                    print("session is too far away")
                }
            }
            userCreationComplete(nearByArray)
        }
    }
    func downloadYourSessions(uid: String, userCreationComplete: @escaping (_ status: [Playlist]) -> ()) {
        var nearByArray = [Playlist]()
        REF_SESSIONS.observeSingleEvent(of: .value) { (sessions) in
            guard let allSessions = sessions.children.allObjects as? [DataSnapshot] else {return}
            for obj in allSessions {
                if obj.key.contains(uid) {
                    let name = obj.childSnapshot(forPath: "ownerName").value as? String
                    let pName = obj.childSnapshot(forPath: "pName").value as? String
                    let oid = obj.childSnapshot(forPath: "oid").value as? String
                    let pid = obj.childSnapshot(forPath: "pid").value as? String
                    let sesh = Playlist(id: pid!, Name: pName!, Owner: name!, uri: "", oid: oid!)
                    nearByArray.append(sesh)
                } else {
                    print("not yours")
                }
                
            }
            userCreationComplete(nearByArray)
        }
    }
    
    func uploadTracks(sessionID: String, songOne: Track, songTwo: Track, songThree: Track, currentSong: Track, completion: @escaping (_ done: Bool) ->()) {
        REF_SESSIONS.child(sessionID).updateChildValues(["songOne":["name": songOne.name,"artist":songOne.artist,"id":songOne.id,"duration":songOne.duration, "votes": 0]])
        REF_SESSIONS.child(sessionID).updateChildValues(["songTwo":["name": songTwo.name,"artist":songTwo.artist,"id":songTwo.id,"duration":songTwo.duration, "votes": 0]])
        REF_SESSIONS.child(sessionID).updateChildValues(["songThree":["name": songThree.name,"artist":songThree.artist,"id":songThree.id,"duration":songThree.duration, "votes": 0]])
        REF_SESSIONS.child(sessionID).updateChildValues(["currentSong":["name": currentSong.name,"artist":currentSong.artist,"id":currentSong.id,"duration":currentSong.duration, "votes": 0]])
        REF_SESSIONS.child(sessionID).updateChildValues(["status":"RESET"])
        completion(true)
    }
    func updateStatus(sessionID: String,completion: @escaping (_ getReady: Bool) -> ()){
        REF_SESSIONS.child(sessionID).updateChildValues(["status":"BEGAN"])
        completion(true)
    }
    func observeStatus(sessionId: String, completion: @escaping (_ getReady: Bool) -> ()){
        REF_SESSIONS.child(sessionId + "/status").observe(.value) { (checkinStatus) in
            completion(false)
        }
    }
    func getInitialTracks(songNumber: String,sessionID: String, completion: @escaping (_ songdictionary: Track) -> ()) {
        REF_SESSIONS.observeSingleEvent(of: .value) { (tracks) in
            guard let seshtracks = tracks.children.allObjects as? [DataSnapshot] else {return}
            for obj in seshtracks {
                if obj.key == sessionID {
                    //print("found session")
                    if obj.hasChild(songNumber){
                    //print("found song")
                    let songName = obj.childSnapshot(forPath: "\(songNumber)/name").value as? String
                    let songArtist = obj.childSnapshot(forPath: "\(songNumber)/artist").value as? String
                    let songId = obj.childSnapshot(forPath: "\(songNumber)/id").value as? String
                    let songDuration = obj.childSnapshot(forPath: "\(songNumber)/duration").value as? Int
                    let song = Track(name: songName!, artist: songArtist!, id: songId!, duration: songDuration!)
                    //print(song)
                    completion(song)
                    }
                }
            }
        }
    }
    func observerForSongChange(songNumber: String, sessionId: String, completion: @escaping (_ song: Track) -> ()){
        REF_SESSIONS.observe(.value) { (nextRound) in
            guard let nextSesh = nextRound.children.allObjects as? [DataSnapshot] else {return}
            for obj in nextSesh {
                if obj.key == sessionId {
                    if obj.hasChild(songNumber) {
                        let songName = obj.childSnapshot(forPath: "\(songNumber)/name").value as? String
                        let songArtist = obj.childSnapshot(forPath: "\(songNumber)/artist").value as? String
                        let songId = obj.childSnapshot(forPath: "\(songNumber)/id").value as? String
                        let songDuration = obj.childSnapshot(forPath: "\(songNumber)/duration").value as? Int
                        let song = Track(name: songName!, artist: songArtist!, id: songId!, duration: songDuration!)
                        //print(song)
                        completion(song)
                    }
                }
            }
        }
    }
    
    func postVotes(sessionId: String, songNumber: String) {
        REF_SESSIONS.child(sessionId + "/" + songNumber).runTransactionBlock { (currentData) -> TransactionResult in
            if var song = currentData.value as? [String: AnyObject] {
                var votes = song["votes"] as? Int ?? 0
                votes += 1
                song["votes"] = votes as AnyObject?
                currentData.value = song
                return TransactionResult.success(withValue: currentData)
            } else {
                print("somehting is wrong")
            }
            return TransactionResult.success(withValue: currentData)
            }
    }
    func getcurrentSong(sessionId: String, completion: @escaping (_ song: Track) -> ()){
        REF_SESSIONS.observe(.value) { (nextRound) in
            guard let nextSesh = nextRound.children.allObjects as? [DataSnapshot] else {return}
            for obj in nextSesh {
                if obj.key == sessionId && obj.hasChild("currentSong") {
                        let songName = obj.childSnapshot(forPath: "currentSong/name").value as? String
                        let songArtist = obj.childSnapshot(forPath: "currentSong/artist").value as? String
                        let songId = obj.childSnapshot(forPath: "currentSong/id").value as? String
                        let songDuration = obj.childSnapshot(forPath: "currentSong/duration").value as? Int
                        let song = Track(name: songName!, artist: songArtist!, id: songId!, duration: songDuration!)
                        //print(song)
                        completion(song)
                }
            }
        }
    }
    func observeForVotes(sessionId: String, songNumber: String, completion: @escaping (_ vote: Int) -> ()){
        REF_SESSIONS.observe(.value) { (votes) in
            guard let voteCount = votes.children.allObjects as? [DataSnapshot] else {return}
            for obj in voteCount {
                if obj.key == sessionId && obj.hasChild(songNumber) {
                    let number = obj.childSnapshot(forPath: "\(songNumber)/votes").value as? Int
                    completion(number!)
                }
            }
        }
    }
    
    func removeSesh(sessionID: String) {
        REF_SESSIONS.child(sessionID).removeValue()
    }
    func saveSongPopularity(songNumbers: String, sessionId: String){
        var location: CLLocation!
        let geocoder = CLGeocoder()
                REF_SESSIONS.observeSingleEvent(of: .value) { (dataSnapShot) in
                    guard let sessionData = dataSnapShot.children.allObjects as? [DataSnapshot] else {return}
                    for obj in sessionData {
                        if obj.key == sessionId {
                            
                            let votes = obj.childSnapshot(forPath: songNumbers + "/votes").value as? Int
                            let lat = obj.childSnapshot(forPath: "latitude").value as? Double
                            let lon = obj.childSnapshot(forPath: "longitude").value as? Double
                            let id = obj.childSnapshot(forPath: songNumbers + "/id").value as? String
                            let artist = obj.childSnapshot(forPath: songNumbers + "/artist").value as? String
                            let name = obj.childSnapshot(forPath: songNumbers + "/name").value as? String
                            
                            location = CLLocation(latitude: lat!, longitude: lon!)
                            geocoder.reverseGeocodeLocation(location, completionHandler: { (placemark, error) in
                                if let address = placemark!.first {
                                    let lines = address.locality
                                    let state = address.administrativeArea
                                    self.REF_SONGS.observeSingleEvent(of: .value, with: { (sdata) in
                                        guard let songdata = sdata.children.allObjects as? [DataSnapshot] else {return}
                                        //print("\(songdata.count)  THIS IS WHAT YO WNAT")
                                        if songdata.count == 0 {
                                            self.REF_SONGS.child(id!).updateChildValues(["song":name ?? "","artist":artist ?? "",state!: [lines!:["votes":Int(votes!)]]])
                                        }
                                            for track in songdata {
                                                if track.key == id && track.hasChild(state!) {
                                                     let oldvotes = obj.childSnapshot(forPath: state! + "/" + lines! + "/votes").value as? Int
                                                        self.REF_SONGS.child(id!).updateChildValues(["song":name ?? "","artist":artist ?? "",state!: [lines!:["votes":Int(oldvotes! + votes!)]]])
                                                    } else { self.REF_SONGS.child(id!).updateChildValues(["song":name ?? "","artist":artist ?? "",state!: [lines!:["votes":Int(votes!)]]])
                                                }
                                            }
                                    })
                                } else {
                                    print(error?.localizedDescription ?? "")
                                }
                                })
                        }
                    }
                }
    }
}
