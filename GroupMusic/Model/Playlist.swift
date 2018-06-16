//
//  Playlist.swift
//  GroupMusic
//
//  Created by Noah Schairer on 4/18/18.
//  Copyright © 2018 nschairer. All rights reserved.
//

import Foundation


class Playlist: NSObject, NSCoding {
    private var _playlistId: String
    private var _playlistName: String
    private var _playlistOwner: String
    private var _playlistUri: String
    private var _oid: String
    
    var oid: String {
        return _oid
    }
    
    var playlistUri:String {
        return _playlistUri
    }
    var playlistId: String {
        return _playlistId
    }
    var playlistName: String {
        return _playlistName
    }
    var playlistOwner: String {
        return _playlistOwner
    }
    init(id:String, Name:String, Owner:String, uri: String, oid: String) {
        self._playlistId = id
        self._playlistName = Name
        self._playlistOwner = Owner
        self._playlistUri = uri
        self._oid = oid
    }
    required convenience init?(coder aDecoder: NSCoder) {
        let pid = aDecoder.decodeObject(forKey: "pid") as! String
        let pName = aDecoder.decodeObject(forKey: "name") as! String
        let pOwner = aDecoder.decodeObject(forKey: "owner") as! String
        let pUri = aDecoder.decodeObject(forKey: "uri") as! String
        let poid = aDecoder.decodeObject(forKey: "oid") as! String

        self.init(id: pid, Name: pName, Owner: pOwner, uri: pUri, oid: poid)
    }
    func encode(with aCoder: NSCoder) {
        aCoder.encode(playlistId, forKey: "pid")
        aCoder.encode(playlistName, forKey: "name")
        aCoder.encode(playlistOwner, forKey: "owner")
        aCoder.encode(playlistUri, forKey: "uri")
        aCoder.encode(oid, forKey: "oid")

    }
}
