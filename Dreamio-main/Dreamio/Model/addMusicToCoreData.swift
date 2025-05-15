
func addMusicToCoreData() {
    let context = CoreDataManager.shared.context

    // Manually recreate the music data
    let musicArray: [(title: String, description: String, image: String, fileName: String)] = [
        ("Gentle Rain", "Calming audio", "1", "Rain.mp3"),
        ("Birds in Forest", "Nature audio", "2", "Waves.mp3"),
        ("Mountain Stream", "Relaxing audio", "3", "White-Noise.mp3"),
        ("Wind Chimes", "Meditative audio", "4", "Waterfall.mp3"),
        ("Night Crickets", "Sleep audio", "5", "Fan.mp3"),
        ("Thunderstorm", "Intense audio", "6", "Ocean.mp3"),
        ("Ocean Waves", "Soothing audio", "7", "Heater.mp3"),
        ("Gentle Breeze", "Light wind sounds", "8", "Fan.mp3"),
        ("Campfire", "Crackling fire", "9", "Dryer.mp3"),
        ("Forest Stream", "Flowing water", "10", "Rain.mp3"),
        ("Underwater", "Bubbling sound", "11", "Waterfall.mp3"),
        ("Desert Winds", "Warm breeze", "12", "Rain.mp3"),
        ("City Rain", "Urban rain", "13", "Rain.mp3"),
        ("Waterfall", "Strong waterfall", "14", "Waves.mp3"),
        ("Jungle Sounds", "Animals and leaves", "15", "Rain.mp3"),
        ("Spring Birds", "Birds chirping", "16", "White-Noise.mp3"),
        ("Waves on Rocks", "Waves crashing", "17", "Waves.mp3"),
        ("Soft Thunder", "Distant thunder", "18", "Rain.mp3"),
        ("Cave Drips", "Water droplets", "19", "Rain.mp3"),
        ("Snowfall", "Soft wind and snow", "20", "Ocean.mp3"),
        ("Ocean Tides", "Tide sounds", "21", "Heater.mp3"),
        ("Summer Nights", "Nighttime insects", "22", "Rain.mp3"),
        ("Deep Forest", "Echoing nature", "23", "Fan.mp3"),
        ("River Rapids", "Fast water flow", "24", "Dryer.mp3"),
        ("Windy Mountain", "Mountain breeze", "25", "Dryer.mp3")
    ]

    // Loop through the music array and insert each item into Core Data
    for music in musicArray {
        let musicEntity = MusicEntity(context: context)
        musicEntity.title = music.title
        musicEntity.descriptions = music.description
        musicEntity.image = music.image
        musicEntity.fileName = music.fileName
        
        // Save context after inserting data
        CoreDataManager.shared.saveContext()
    }
}
