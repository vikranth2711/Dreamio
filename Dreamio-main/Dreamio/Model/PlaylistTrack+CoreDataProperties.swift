//
//  PlaylistTrack+CoreDataProperties.swift
//  
//
//  Created by user@31 on 17/03/25.
//
//

import Foundation
import CoreData


extension PlaylistTrack {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlaylistTrack> {
        return NSFetchRequest<PlaylistTrack>(entityName: "PlaylistTrack")
    }

    @NSManaged public var volume: Float
    @NSManaged public var playlist: PlaylistEntity?
    @NSManaged public var music: MusicEntity?

}
