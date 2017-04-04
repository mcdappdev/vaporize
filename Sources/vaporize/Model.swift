import Console
import Foundation

public final class Model: Command {
    public let id = "model"
    
    public let signature: [Argument] = [
    
    ]
    
    public let help: [String] = [
        "Creates a model"
    ]
    
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        do {
            let currentPath = FileManager.default.currentDirectoryPath
            let packageFilePath = currentPath + "/Package.swift"
            let modelsFolderPath = currentPath + "/Sources/AppLogic/Models"
            
            if !FileManager.default.fileExists(atPath: packageFilePath) {
                throw ErrorCase.generalError("This is not a Vapor project. Please execute Vaporize in a Vapor project")
            }
            
            let directoryOfTemplates = "\(NSHomeDirectory())/.vaporize"
            let modelFile = "\(directoryOfTemplates)/model.swift"
            
            //require at least the name and one property
            var args = arguments
            if args.count < 2 {
                throw ConsoleError.insufficientArguments
            }
            
            let modelName = args[0]
            let dbName = modelName.lowercased().pluralized
            args.remove(at: 0)
            let properties = try args.map { try Property(fullString: $0) }
            
            //holder strings
            var propertyString = ""
            var propertyInitString = ""
            var propertyMakeNode = ""
            var builder = ""
            
            var firstInitProperties = ""
            var fiAssignString = ""
            
            for (index, property) in properties.enumerated() {
                let isLast = index == properties.count - 1
                let isFirst = index == 0
                
                if !isFirst {
                    propertyString += space(count: 4)
                    fiAssignString += space(count: 8)
                    propertyInitString += space(count: 8)
                    propertyMakeNode += space(count: 12)
                    builder += space(count: 12)
                }
                
                firstInitProperties += "\(property.name): \(property.type.rawValue.capitalized)"
                fiAssignString += "self.\(property.name) = \(property.name)"
                
                propertyString += "var \(property.name): \(property.type.rawValue.capitalized)!"
                propertyInitString += "\(property.name) = try node.extract(\"\(property.name)\")"
                propertyMakeNode += "\"\(property.name)\": \(property.name)"
                builder += "builder.\(property.type.rawValue)(\"\(property.name)\")"
                
                if !isLast {
                    //if it's not the last item, add a comma to the node array and add a new line to everything else
                    propertyMakeNode += ","
                    propertyString += "\n"
                    propertyInitString += "\n"
                    propertyMakeNode += "\n"
                    builder += "\n"
                    
                    firstInitProperties += ", "
                } 
            }
            
            let contentsOfModelTemplate = try String(contentsOfFile: modelFile)
            var newModel = contentsOfModelTemplate
            
            newModel = newModel.replacingOccurrences(of: .modelName, with: modelName)
            newModel = newModel.replacingOccurrences(of: .properties, with: propertyString)
            newModel = newModel.replacingOccurrences(of: .firstInit, with: firstInitProperties)
            newModel = newModel.replacingOccurrences(of: .fiAssign, with: fiAssignString)
            newModel = newModel.replacingOccurrences(of: .propertiesInit, with: propertyInitString)
            newModel = newModel.replacingOccurrences(of: .propertiesMakeNode, with: propertyMakeNode)
            newModel = newModel.replacingOccurrences(of: .dbName, with: dbName)
            newModel = newModel.replacingOccurrences(of: .builder, with: builder)
            
            try newModel.write(toFile: "\(modelsFolderPath)/\(modelName).swift", atomically: true, encoding: .utf8)
        } catch {
            console.error(error.localizedDescription, newLine: true)
        }
    }
    
    func space(count: Int) -> String {
        if count < 0 {
            return ""
        }
        
        var spaces = ""
        for _ in 0 ..< count {
            spaces += " "
        }
        return spaces
    }
}

enum ModelKeys: String {
    case modelName = "VAR_MODEL_NAME"
    case properties = "VAR_PROPERTIES"
    case propertiesInit = "VAR_INIT"
    case propertiesMakeNode = "VAR_MAKE_NODE"
    case dbName = "VAR_DB_NAME"
    case builder = "VAR_BUILDER"
    case firstInit = "VAR_FIRST_INIT_PROPERTIES"
    case fiAssign = "VAR_FI_ASSIGN"
}

struct Property {
    let name: String
    let type: PropertyType
    
    init(name: String, type: String) throws {
        guard let propertyType = PropertyType(rawValue: type) else {
            throw ConsoleError.insufficientArguments
        }
        
        self.name = name
        self.type = propertyType
    }
    
    init(fullString: String) throws {
        let splitStrings = fullString.components(separatedBy: ":")
        if splitStrings.count != 2 {
            throw ConsoleError.insufficientArguments
        }
        
        try self.init(name: splitStrings[0], type: splitStrings[1])
    }
}

enum PropertyType: String {
    case int
    case string
    case double
    case bool
}

extension String {
    public var pluralized: String {
        return plural()
    }
    
    func plural() -> String {
        return self + "s"
    }
}

fileprivate extension String {
    func replacingOccurrences(of: ModelKeys, with: String) -> String {
        return replacingOccurrences(of: of.rawValue, with: with)
    }
}
