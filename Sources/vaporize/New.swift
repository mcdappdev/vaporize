import Console
import Foundation

public final class New: Command {
    public let id = "new"
    
    public let signature: [Argument] = []
    
    public let help: [String] = [
        "Creates a new Vapor project",
        "based on the template"
    ]
    
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public func run(arguments: [String]) throws {
        guard let nameOfProject = arguments.first else {
            throw ErrorCase.generalError("Please specify a name for the project")
        }

        _ = console.loadingBar()
        _ = try console.backgroundExecute(program: "vapor", arguments: ["new", nameOfProject, "--template=https://github.com/mcdappdev/Vapor-Template"])
        _ = try console.backgroundExecute(program: "cd", arguments: [nameOfProject])
        console.success()
        
        let packageName = console.ask("Project Name (For Package.swift):")
        let mysqlHost = console.ask("MySQL Host:")
        let mysqlUser = console.ask("MySQL User:")
        let mysqlPassword = console.ask("MySQL Password:")
        let mysqlPort = console.ask("MySQL Port:")
        let mysqlDatabase = console.ask("MySQL Database:")
        
        let redisAddress = console.ask("Redis Address:")
        let redisPort = console.ask("Redis Port (typically 6379):")
        
        let directoryOfProject = FileManager.default.currentDirectoryPath + "/" + nameOfProject
        
        let directoryOfTemplates = "\(NSHomeDirectory())/.vaporize"
        
        let mysqlPath = "\(directoryOfProject)/Config/development/mysql.json"
        let redisPath = "\(directoryOfProject)/Config/development/redis.json"
        let gitignorePath = "\(directoryOfProject)/.gitignore"
        
        let mysqlTemplatePath = "\(directoryOfTemplates)/mysql.json"
        let redisTemplatePath = "\(directoryOfTemplates)/redis.json"
        let gitignoreTemplatePath = "\(directoryOfTemplates)/.gitignore"
        
        let packageFilePath = "\(directoryOfProject)/Package.swift"
        
        _ = console.loadingBar()
        
        do {
            _ = try console.backgroundExecute(program: "mkdir", arguments: ["\(directoryOfProject)/Config/development"])
            
            if !FileManager.default.fileExists(atPath: packageFilePath) {
                throw ErrorCase.generalError("This is not a Vapor project. Please execute Vaporize in a Vapor project")
            }
            
            if !FileManager.default.fileExists(atPath: "\(directoryOfProject)/Config") {
                throw ErrorCase.generalError("No Config directory found.")
            }
            
            if !FileManager.default.fileExists(atPath: "\(directoryOfProject)/Config/development") {
                throw ErrorCase.generalError("No 'development' directory in 'Config' found.")
            }
            
            if FileManager.default.fileExists(atPath: mysqlPath) {
                _ = try console.backgroundExecute(program: "rm", arguments: [mysqlPath])
            }
            
            if FileManager.default.fileExists(atPath: redisPath) {
                _ = try console.backgroundExecute(program: "rm", arguments: [redisPath])
            }
            
            _ = try console.backgroundExecute(program: "touch", arguments: [mysqlPath])
            _ = try console.backgroundExecute(program: "touch", arguments: [redisPath])
            
            let contentsOfMysqlFile = try String(contentsOfFile: mysqlTemplatePath)
            let contentsOfRedisFile = try String(contentsOfFile: redisTemplatePath)
            let contentsOfPackageFile = try String(contentsOfFile: packageFilePath)
            let contentsOfGitignoreFile = try String(contentsOfFile: gitignoreTemplatePath)
            
            var filledInMysqlFile = contentsOfMysqlFile
            var filledInRedisFile = contentsOfRedisFile
            var filledInPackageFile = contentsOfPackageFile
            
            filledInMysqlFile = filledInMysqlFile.replacingOccurrences(of: .user, with: mysqlUser)
            filledInMysqlFile = filledInMysqlFile.replacingOccurrences(of: .password, with: mysqlPassword)
            filledInMysqlFile = filledInMysqlFile.replacingOccurrences(of: .host, with: mysqlHost)
            filledInMysqlFile = filledInMysqlFile.replacingOccurrences(of: .port, with: mysqlPort)
            filledInMysqlFile = filledInMysqlFile.replacingOccurrences(of: .database, with: mysqlDatabase)
            
            filledInRedisFile = filledInRedisFile.replacingOccurrences(of: .address, with: redisAddress)
            filledInRedisFile = filledInRedisFile.replacingOccurrences(of: .redisPort, with: redisPort)
            
            filledInPackageFile = filledInPackageFile.replacingOccurrences(of: .name, with: packageName)
            
            try filledInMysqlFile.write(toFile: mysqlPath, atomically: true, encoding: .utf8)
            try filledInRedisFile.write(toFile: redisPath, atomically: true, encoding: .utf8)
            try filledInPackageFile.write(toFile: packageFilePath, atomically: true, encoding: .utf8)
            
            if FileManager.default.fileExists(atPath: gitignorePath) {
                _ = try console.backgroundExecute(program: "rm", arguments: [gitignorePath])
            }
            
            FileManager.default.changeCurrentDirectoryPath(directoryOfProject)
            _ = try console.backgroundExecute(program: "rm", arguments: ["-rf", ".git"])
            try contentsOfGitignoreFile.write(toFile: gitignorePath, atomically: true, encoding: .utf8)
            console.success()
        } catch {
            console.error()
            console.error(error.localizedDescription, newLine: true)
        }
        
        var createDatabaseAnswer = ""
        while createDatabaseAnswer != "y" && createDatabaseAnswer != "n" {
            createDatabaseAnswer = console.ask("Create MySQL Database? (y/n)").lowercased()
        }
        
        if createDatabaseAnswer == "y" {
            _ = try console.foregroundExecute(program: "mysql", arguments: ["--user", "\(mysqlUser)", "--password=\(mysqlPassword)", "-e", "CREATE DATABASE \(mysqlDatabase)"])
        }
        
        var answer = ""
        while answer != "y" && answer != "n" {
            answer = console.ask("Create Xcode project? (y/n)").lowercased()
        }
        
        if answer == "y" {
            FileManager.default.changeCurrentDirectoryPath(directoryOfProject)
            _ = try console.foregroundExecute(program: "vapor", arguments: ["xcode", "-y"])
        }
        
        _ = try console.foregroundExecute(program: "cd", arguments: [directoryOfProject])
    }
}

fileprivate extension String {
    func replacingOccurrences(of: MySQLKey, with: String) -> String {
        return replacingOccurrences(of: of.rawValue, with: with)
    }
    
    func replacingOccurrences(of: RedisKey, with: String) -> String {
        return replacingOccurrences(of: of.rawValue, with: with)
    }
    
    func replacingOccurrences(of: PackageKey, with: String) -> String {
        return replacingOccurrences(of: of.rawValue, with: with)
    }
}

enum PackageKey: String {
    case name = "PROJECT_NAME"
}

enum MySQLKey: String {
    case user = "MYSQL_USER"
    case password = "MYSQL_PASSWORD"
    case host = "MYSQL_HOST"
    case port = "MYSQL_PORT"
    case database = "MYSQL_DATABASE"
}

enum RedisKey: String {
    case address = "REDIS_ADDRESS"
    case redisPort = "REDIS_PORT"
}

enum ErrorCase: Error {
    case generalError(String)
}
