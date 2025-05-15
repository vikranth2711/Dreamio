//
//  PlaylistEntity+CoreDataProperties.swift
//  
//
//  Created by user@31 on 17/03/25.
//
//

import Foundation
import CoreData


extension PlaylistEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlaylistEntity> {
        return NSFetchRequest<PlaylistEntity>(entityName: "PlaylistEntity")
    }

    @NSManaged public var name: String?
    @NSManaged public var tracks: NSSet?

}

// MARK: Generated accessors for tracks
extension PlaylistEntity {

    @objc(addTracksObject:)
    @NSManaged public func addToTracks(_ value: PlaylistTrack)

    @objc(removeTracksObject:)
    @NSManaged public func removeFromTracks(_ value: PlaylistTrack)

    @objc(addTracks:)
    @NSManaged public func addToTracks(_ values: NSSet)

    @objc(removeTracks:)
    @NSManaged public func removeFromTracks(_ values: NSSet)

}
