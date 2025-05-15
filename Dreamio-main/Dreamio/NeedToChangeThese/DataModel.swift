
import Foundation

struct PersonalInfo: Codable {
    var name: String
    var id: String
    var password: String
}


class DataModel {
    static let shared = DataModel()
    private let fileName = "personalInfo.json"
    
    private var profileDirectoryURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let profileFolderURL = directory.appendingPathComponent("Profile")
        
        if !FileManager.default.fileExists(atPath: profileFolderURL.path) {
            do {
                try FileManager.default.createDirectory(at: profileFolderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating Profile directory: \(error)")
            }
        }
        return profileFolderURL
    }
    
    private var fileURL: URL {
        return profileDirectoryURL.appendingPathComponent(fileName)
    }
    
    // Function to save name, id, or password individually
    func saveName(_ name: String) {
        var currentInfo = load() ?? PersonalInfo(name: "", id: "", password: "")
        currentInfo.name = name
        save(info: currentInfo)
    }
    
    func saveID(_ id: String) {
        var currentInfo = load() ?? PersonalInfo(name: "", id: "", password: "")
        currentInfo.id = id
        save(info: currentInfo)
    }
    
    func savePassword(_ password: String) {
        var currentInfo = load() ?? PersonalInfo(name: "", id: "", password: "")
        currentInfo.password = password
        save(info: currentInfo)
    }
    
    // Private function to save the entire PersonalInfo object
    private func save(info: PersonalInfo) {
        do {
            let data = try JSONEncoder().encode(info)
            try data.write(to: fileURL)
            print("Data saved to \(fileURL.path)")
        } catch {
            print("Error saving data: \(error)")
        }
    }
    
    // Function to load the saved PersonalInfo
    func load() -> PersonalInfo? {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(PersonalInfo.self, from: data)
        } catch {
            print("Error loading data: \(error)")
            return nil
        }
    }
}
