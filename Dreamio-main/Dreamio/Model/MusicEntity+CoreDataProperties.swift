//
//  MusicEntity+CoreDataProperties.swift
//  
//
//  Created by user@31 on 17/03/25.
//
//

import Foundation
import CoreData


extension MusicEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MusicEntity> {
        return NSFetchRequest<MusicEntity>(entityName: "MusicEntity")
    }

    @NSManaged public var descriptions: String?
    @NSManaged public var fileName: String?
    @NSManaged public var image: String?
    @NSManaged public var musicID: UUID?
    @NSManaged public var title: String?
    @NSManaged public var playlistTracks: NSSet?

}

// MARK: Generated accessors for playlistTracks
extension MusicEntity {

    @objc(addPlaylistTracksObject:)
    @NSManaged public func addToPlaylistTracks(_ value: PlaylistTrack)

    @objc(removePlaylistTracksObject:)
    @NSManaged public func removeFromPlaylistTracks(_ value: PlaylistTrack)

    @objc(addPlaylistTracks:)
    @NSManaged public func addToPlaylistTracks(_ values: NSSet)

    @objc(removePlaylistTracks:)
    @NSManaged public func removeFromPlaylistTracks(_ values: NSSet)

}
