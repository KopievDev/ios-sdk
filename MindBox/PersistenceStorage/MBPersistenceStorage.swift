//
//  MBPersistenceStorage.swift
//  MindBox
//
//  Created by Maksim Kazachkov on 02.02.2021.
//  Copyright © 2021 Mikhail Barilov. All rights reserved.
//

import Foundation

class MBPersistenceStorage: PersistenceStorage {
    
    // MARK: - Dependency
    static var defaults: UserDefaults = .standard
    
    // MARK: - Property
    var isInstalled: Bool {
        installationDate != nil
    }
    
    var installationDate: Date? {
        get {
            let dateFormater = DateFormatter()
            dateFormater.dateStyle = .full
            dateFormater.timeStyle = .full
            if let dateString = installationDateString {
                return dateFormater.date(from: dateString)
            } else {
                return nil
            }
        }
        set {
            let dataFormater = DateFormatter()
            dataFormater.dateStyle = .full
            dataFormater.timeStyle = .full
            if let date = newValue {
                installationDateString = dataFormater.string(from: date)
            } else {
                installationDateString = nil
            }
        }
    }
    
    var apnsTokenSaveDate: Date? {
        get {
            let dateFormater = DateFormatter()
            dateFormater.dateStyle = .full
            dateFormater.timeStyle = .full
            if let dateString = apnsTokenSaveDateString {
                return dateFormater.date(from: dateString)
            } else {
                return nil
            }
        }
        set {
            let dataFormater = DateFormatter()
            dataFormater.dateStyle = .full
            dataFormater.timeStyle = .full
            if let date = newValue {
                apnsTokenSaveDateString = dataFormater.string(from: date)
            } else {
                apnsTokenSaveDateString = nil
            }
        }
    }
    
    var deprecatedEventsRemoveDate: Date? {
        get {
            let dateFormater = DateFormatter()
            dateFormater.dateStyle = .full
            dateFormater.timeStyle = .full
            if let dateString = deprecatedEventsRemoveDateString {
                return dateFormater.date(from: dateString)
            } else {
                return nil
            }
        }
        set {
            let dataFormater = DateFormatter()
            dataFormater.dateStyle = .full
            dataFormater.timeStyle = .full
            if let date = newValue {
                deprecatedEventsRemoveDateString = dataFormater.string(from: date)
            } else {
                deprecatedEventsRemoveDateString = nil
            }
        }
    }
    
    var configuration: MBConfiguration? {
        get {
            guard let data = configurationData else {
                return nil
            }
            return try? JSONDecoder().decode(MBConfiguration.self, from: data)
        }
        set {
            if let data = newValue {
                configurationData = try? JSONEncoder().encode(data)
            } else {
                configurationData = nil
            }
        }
    }
    
    var backgroundExecutions: [BackgroudExecution] {
        get {
            if let data = MBPersistenceStorage.defaults.value(forKey:"backgroundExecution") as? Data {
                return (try? PropertyListDecoder().decode(Array<BackgroudExecution>.self, from: data)) ?? []
            } else {
                return []
            }
        }
    }
    
    func setBackgroundExecution(_ value: BackgroudExecution) {
        var tasks = backgroundExecutions
        tasks.append(value)
        MBPersistenceStorage.defaults.set(try? PropertyListEncoder().encode(tasks), forKey:"backgroundExecution")
        MBPersistenceStorage.defaults.synchronize()
    }
    
    func storeToFileBackgroundExecution() {
        let path = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BackgroundExecution.plist")
        
        // Swift Dictionary To Data.
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        do {
            let data = try encoder.encode(backgroundExecutions)
            try data.write(to: path)
            Log("Successfully storeToFileBackgroundExecution")
                .inChanel(.system).withType(.info).make()
        } catch {
            Log("StoreToFileBackgroundExecution did failed with error: \(error.localizedDescription)")
                .inChanel(.system).withType(.info).make()
        }
    }
    
    
    // MARK: - Init
    init(defaults: UserDefaults) {
        MBPersistenceStorage.defaults = defaults
    }

    // MARK: - IMBMBPersistenceStorage
    @UserDefaultsWrapper(key: .deviceUUID, defaultValue: nil)
    var deviceUUID: String? {
        didSet {
            configuration?.deviceUUID = deviceUUID
        }
    }

    @UserDefaultsWrapper(key: .installationId, defaultValue: nil)
    var installationId: String?

    @UserDefaultsWrapper(key: .apnsToken, defaultValue: nil)
    var apnsToken: String? {
        didSet {
            apnsTokenSaveDate = Date()
        }
    }

    @UserDefaultsWrapper(key: .apnsTokenSaveDate, defaultValue: nil)
    private var apnsTokenSaveDateString: String?
    
    @UserDefaultsWrapper(key: .deprecatedEventsRemoveDate, defaultValue: nil)
    private var deprecatedEventsRemoveDateString: String?
    
    @UserDefaultsWrapper(key: .configurationData, defaultValue: nil)
    private var configurationData: Data?
    
    @UserDefaultsWrapper(key: .isNotificationsEnabled, defaultValue: nil)
    var isNotificationsEnabled: Bool?
    
    @UserDefaultsWrapper(key: .installationData, defaultValue: nil)
    private var installationDateString: String?


    func reset() {
        installationDate = nil
        deviceUUID = nil
        installationId = nil
        apnsToken = nil
        apnsTokenSaveDate = nil
        deprecatedEventsRemoveDate = nil
        configuration = nil
        isNotificationsEnabled = nil
        resetBackgroundExecutions()
    }
    
    func resetBackgroundExecutions() {
        MBPersistenceStorage.defaults.removeObject(forKey: "backgroundExecution")
        MBPersistenceStorage.defaults.synchronize()
    }

    // MARK: - Private

}

struct BackgroudExecution: Codable {
    
    let taskID: String
    
    let taskName: String
    
    let dateString: String
    
    let info: String
    
}

extension MBPersistenceStorage {
    
    @propertyWrapper
    struct UserDefaultsWrapper<T> {
        
        enum Key: String {
            
            case installationId = "MBPersistenceStorage-installationId"
            case deviceUUID = "MBPersistenceStorage-deviceUUID"
            case apnsToken = "MBPersistenceStorage-apnsToken"
            case apnsTokenSaveDate = "MBPersistenceStorage-apnsTokenSaveDate"
            case deprecatedEventsRemoveDate = "MBPersistenceStorage-deprecatedEventsRemoveDate"
            case configurationData = "MBPersistenceStorage-configurationData"
            case isNotificationsEnabled = "MBPersistenceStorage-isNotificationsEnabled"
            case installationData = "MBPersistenceStorage-installationData"
        }
        
        private let key: Key
        private let defaultValue: T?
        
        init(key: Key, defaultValue: T?) {
            self.key = key
            self.defaultValue = defaultValue
        }
        
        var wrappedValue: T? {
            get {
                // Read value from UserDefaults
                let isExists = defaults.isValueExists(forKey: key.rawValue)
                let value = MBPersistenceStorage.defaults.value(forKey: key.rawValue) as? T ?? defaultValue
                return isExists ? value : defaultValue
            }
            set {
                // Set value to UserDefaults
                MBPersistenceStorage.defaults.setValue(newValue, forKey: key.rawValue)
                MBPersistenceStorage.defaults.synchronize()
            }
        }
        
    }
    
}

fileprivate extension UserDefaults {

    func isValueExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }

}