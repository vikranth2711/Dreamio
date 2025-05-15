import CoreData

class DataPreloader {
    static func preloadData() {
        let context = CoreDataManager.shared.context

        // Check if data is already loaded to avoid duplication
        let fetchRequest: NSFetchRequest<MusicEntity> = MusicEntity.fetchRequest() // Use MusicEntity here
        do {
            let count = try context.count(for: fetchRequest)
            if count > 0 {
                print("Data already preloaded.")
                return // Data already exists, no need to preload
            }
        } catch {
            print("Error checking existing data: \(error)")
        }

        // Preload static music data from Core Data using DataModel1.getAllMusic()
        let staticMusics = DataModel1.getAllMusic() // Access your music data through DataModel1
        for music in staticMusics {
            let musicEntity = MusicEntity(context: context) // Use MusicEntity here
            musicEntity.title = music.title
            musicEntity.descriptions = music.descriptions
            musicEntity.image = music.image
            musicEntity.fileName = music.fileName
            musicEntity.musicID = music.musicID // Assuming you're storing the musicID directly
        }

        // Save the context
        do {
            try context.save()
            print("Static data preloaded into Core Data.")
        } catch {
            print("Error saving preloaded data: \(error)")
        }
    }
}
