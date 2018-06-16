//
//  PlaylistCell.swift
//  GroupMusic
//
//  Created by Noah Schairer on 4/18/18.
//  Copyright © 2018 nschairer. All rights reserved.
//

import UIKit

class PlaylistCell: UITableViewCell {
    @IBOutlet weak var playlistNamelbl: UILabel!
    
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(playlist: Playlist) {
        playlistNamelbl.text = playlist.playlistName
    }

}
