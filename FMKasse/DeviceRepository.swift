import Foundation

class DeviceRepository: ObservableObject {
    static let shared = DeviceRepository()
    private let key = "selectedMachineId"
    
    @Published var selectedMachineId: Int64? {
        didSet {
            if let id = selectedMachineId {
                UserDefaults.standard.set(id, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
    
    private init() {
        if let value = UserDefaults.standard.object(forKey: key) as? Int64 {
            selectedMachineId = value
        } else if let value = UserDefaults.standard.object(forKey: key) as? NSNumber {
            selectedMachineId = value.int64Value
        } else {
            selectedMachineId = nil
        }
    }
}
