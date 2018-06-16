//
//  Track.swift
//  GroupMusic
//
//  Created by Noah Schairer on 4/18/18.
//  Copyright © 2018 nschairer. All rights reserved.
//

import Foundation
class Track {
    private var _name: String!
    private var _artist: String!
    private var _id: String!
    private var _duration: Int!
    var duration: Int {
        return _duration
    }
    var name: String {
        return _name
    }
    var artist: String {
        return _artist
    }
    var id: String {
        return _id
    }
    init(name: String, artist: String, id: String, duration: Int) {
        self._artist = artist
        self._name = name
        self._id = id
        self._duration = duration
    }
}
