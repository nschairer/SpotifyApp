//
//  UserVC.swift
//  GroupMusic
//
//  Created by Noah Schairer on 4/18/18.
//  Copyright © 2018 nschairer. All rights reserved.
//

import UIKit
import Alamofire
import CoreLocation
import Firebase
class UserVC: UIViewController, CLLocationManagerDelegate  {
    @IBOutlet weak var userNamelbl: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var yourSessions: UIButton!
    @IBOutlet weak var sessionsNearby: UIButton!
    @IBOutlet weak var mainTableView: UITableView!
    @IBOutlet weak var dismissSelectBtn: UIButton!
    
    @IBOutlet weak var selectTableView: UITableView!
    
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!

    
    var myPlaylistArray = [Playlist]()
    var selectedArray = [Playlist]()
    
    var nearbyArray = [Playlist]()

    var selectedCell = [Int]()
    var userid: String!
    
    var locationManager = CLLocationManager()
    
    var yours = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileImage.layer.cornerRadius = profileImage.frame.size.height / 2
        profileImage.layer.masksToBounds = true
        bgView.layer.cornerRadius = 20
        selectTableView.layer.cornerRadius = 20
        updateAfterFirstLogin()
        mainTableView.delegate = self
        mainTableView.dataSource = self
        selectTableView.delegate = self
        selectTableView.dataSource = self
        mainTableView.reloadData()
        locationManager.delegate = self
        // 2
        locationManager.requestAlwaysAuthorization()
        // Do any additional setup after loading the view.
        
        
    }
    @IBAction func dismissSelect(_ sender: Any) {
        bgView.isHidden = false
        selectTableView.isHidden = true
        dismissSelectBtn.isHidden = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
    }
    @objc func updateAfterFirstLogin () {
        if let sessionObj:AnyObject = UserDefaults.standard.value(forKey: "SpotifySession") as AnyObject? {
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            self.session = firstTimeSession
            getUserInfo()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    @IBAction func sessionsNearbyClick(_ sender: Any) {
        DataService.instance.downloadNearbySessions(currentLocation: locationManager.location!) { (returnedArray) in
            self.selectedArray = returnedArray
            self.mainTableView.reloadData()
        }
        yourSessions.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        yourSessions.setTitleColor(#colorLiteral(red: 0.9921568627, green: 0.9921568627, blue: 0.9921568627, alpha: 1), for: .normal)
        sessionsNearby.backgroundColor = #colorLiteral(red: 0.6196078431, green: 0.6196078431, blue: 0.6196078431, alpha: 1)
        sessionsNearby.setTitleColor(#colorLiteral(red: 0.9921568627, green: 0.9921568627, blue: 0.9921568627, alpha: 1), for: .normal)
        yours = false
    }
    @IBAction func yourSessionsClick(_ sender: Any) {
        DataService.instance.downloadYourSessions(uid: userid) { (returnedArray) in
            self.selectedArray = returnedArray
            self.mainTableView.reloadData()
        }
        sessionsNearby.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        sessionsNearby.setTitleColor(#colorLiteral(red: 0.9921568627, green: 0.9921568627, blue: 0.9921568627, alpha: 1), for: .normal)
        yourSessions.backgroundColor = #colorLiteral(red: 0.6196078431, green: 0.6196078431, blue: 0.6196078431, alpha: 1)
        yourSessions.setTitleColor(#colorLiteral(red: 0.9921568627, green: 0.9921568627, blue: 0.9921568627, alpha: 1), for: .normal)
        yours = true
    }
    
    @IBAction func addplaylistClicked(_ sender: Any) {
        bgView.isHidden = true
        selectTableView.isHidden = false
        dismissSelectBtn.isHidden = false
        
    }
   
    
    func getUserInfo() {
        
        SPTUser.requestCurrentUser(withAccessToken:(session.accessToken)!) { (error, data) in
            guard let user = data as? SPTUser else { print("Couldn't cast as SPTUser"); return }
            if let image = user.largestImage {
            self.profileImage.downloadedFrom(url: image.imageURL)
            } else {
                
            }
            print(user.largestImage ?? "error with image")
            let uid = user.uri.absoluteString.replacingOccurrences(of: "spotify:user:", with: "")
            self.userid = uid
            print(self.userid, user.emailAddress, user.canonicalUserName)
            DataService.instance.downloadYourSessions(uid: uid, userCreationComplete: { (returnedarray) in
                self.selectedArray = returnedarray
                self.mainTableView.reloadData()
            })
            DataService.instance.getDBName(uid: (Auth.auth().currentUser?.uid)!) { (name) in
                self.userNamelbl.text = name
                self.getUserPlaylists(uid: uid, name: name)
            }
        }
    }
    func getUserPlaylists(uid: String, name: String) {
    let url =     "https://api.spotify.com/v1/users/\(uid)/playlists"
    Alamofire.request(url,method:.get,parameters:nil,encoding:JSONEncoding.default,headers:["Authorization": "Bearer " + session.accessToken!]).responseJSON { (response) in
        guard let json = response.result.value as? [String: Any] else{return}
    var playlist: Playlist!
    if let items = json["items"] as? [Dictionary<String, AnyObject>] {
            for obj in items {
                //print(obj)
                playlist = Playlist(id: obj["id"] as! String, Name: obj["name"] as! String, Owner:name, uri: obj["uri"] as! String, oid: uid)
                self.myPlaylistArray.append(playlist)
                //print(self.myPlaylistArray.count)
            }
        }
        self.selectTableView.reloadData()
    }
  }
    
    
    
}


extension UserVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.selectTableView {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AddPlaylist") as? PlaylistCell else {return UITableViewCell()}
        let playlist:Playlist
        if myPlaylistArray.count == 0 {
            return PlaylistCell()
        } else {
        playlist = myPlaylistArray[indexPath.row]
        cell.configure(playlist: playlist)
        }
        return cell
        } else if tableView == mainTableView {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell") as? PlaylistCell else {return UITableViewCell()}
            let playlist: Playlist!
            if selectedArray.count == 0 {
                return PlaylistCell()
            } else {
                playlist = selectedArray[indexPath.row]
                cell.configure(playlist: playlist)
            }
            return cell
        }
        return UITableViewCell()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == selectTableView {
            if myPlaylistArray.count == 0 {
                return 0
            } else {
                return myPlaylistArray.count
            }
        } else if tableView == mainTableView {
            if selectedArray.count == 0 {
                return 0
            } else {
                return selectedArray.count
            }
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == mainTableView {
        let row = [indexPath.row]
        selectedCell = row
        tableView.beginUpdates()
        tableView.endUpdates()
        
        let playlist = selectedArray[indexPath.row]
            
            if yours {
                let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let uvc = storyBoard.instantiateViewController(withIdentifier: "SessionVC") as? SessionVC
                uvc?.playlistId = playlist.playlistId
                uvc?.playListName = playlist.playlistName
                uvc?.owner = playlist.playlistOwner
                uvc?.userId = playlist.oid
                self.present(uvc!, animated: true, completion: nil)
            } else {
                let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let nvc = storyBoard.instantiateViewController(withIdentifier: "NearbyVC") as? NearbyVC
                nvc?.pid = playlist.playlistId
                nvc?.pName = playlist.playlistName
                nvc?.oName = playlist.playlistOwner
                nvc?.oid = playlist.oid
                self.present(nvc!, animated: true, completion: nil)
            }

        } else if tableView == selectTableView {
            DataService.instance.createSession(latitude: (locationManager.location?.coordinate.latitude)!,longitude:(locationManager.location?.coordinate.longitude)!, status: "PUBLIC", ownerName: myPlaylistArray[indexPath.row].playlistOwner, ownerId: userid, playlistId:myPlaylistArray[indexPath.row].playlistId, playlistName: myPlaylistArray[indexPath.row].playlistName)
            selectedArray.append(myPlaylistArray[indexPath.row])
            selectTableView.isHidden = true
            bgView.isHidden = false
            mainTableView.reloadData()

        }
        
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if [indexPath.row] == selectedCell {
            return 175
        } else {
            return 75
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableView == mainTableView {
            return true
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "DELETE") { (rowAction, indexPath)
            in
            DataService.instance.removeSesh(sessionID: self.userid + self.selectedArray[indexPath.row].playlistId)
            self.selectedArray.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.reloadData()
        }
        deleteAction.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        if yours && tableView == mainTableView {
            return [deleteAction]

        }
        return nil
    }
    
}

extension UIImageView {
        func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
            contentMode = mode
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                    let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                    let data = data, error == nil,
                    let image = UIImage(data: data)
                    else { return }
                DispatchQueue.main.async() { () -> Void in
                    self.image = image
                }
                }.resume()
        }
        func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
            guard let url = URL(string: link) else { return }
            downloadedFrom(url: url, contentMode: mode)
        }
}

