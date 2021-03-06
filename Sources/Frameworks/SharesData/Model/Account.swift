//
//  Account.swift
//  SharesData
//
//  Created by Ian McDowell on 4/8/18.
//  Copyright © 2018 Ian McDowell. All rights reserved.
//

import Foundation
import CoreData
import ConnectionKit

@objc(Account)
public class Account: NSManagedObject {

    private class func fetchRequest() -> NSFetchRequest<Account> {
        return NSFetchRequest<Account>(entityName: "Account")
    }

    /// Relative path in storage
    @NSManaged internal var id: String

    @NSManaged public var addresses: [String]
    @NSManaged public var name: String
    @NSManaged public var port: Int16
    @NSManaged internal var type: String
    @NSManaged public var username: String

    public var connectionType: ConnectionManager.Connection? {
        return ConnectionManager.availableConnections.first(where: { $0.bundleID == self.type })
    }
    public var connectionTypeName: String {
        return connectionType?.type.displayName ?? "Unknown Connection Type"
    }

    public static var all: [Account] {
        let request: NSFetchRequest<Account> = Account.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor.init(key: #keyPath(Account.name), ascending: true)
        ]
        do {
            return try Persistence.fetch(request)
        } catch {
            fatalError("Unable to fetch accounts")
        }
    }

    public static func withID(_ id: String) -> Account? {
        let request: NSFetchRequest<Account> = Account.fetchRequest()
        request.predicate = NSPredicate.init(format: "id == %@", id)
        request.fetchLimit = 1
        do {
            return try Persistence.fetch(request).first
        } catch {
            fatalError("Unable to fetch account with id \(id)")
        }
    }

    public static func create(
        name: String,
        type: ConnectionManager.Connection,
        username: String,
        password: String,
        addresses: [String],
        port: Int16
    ) throws -> Account {

        let context = Persistence.container.viewContext
        let account = Account(context: context)

        account.name = name
        account.type = type.bundleID
        account.username = username
        account.addresses = addresses
        account.port = port

        // TODO: Save password to keychain

        try context.save()
        return account
    }

    public func delete() {
        Persistence.container.viewContext.delete(self)
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()

        self.id = UUID().uuidString
    }

    public override func didSave() {
        super.didSave()

        let domain = NSFileProviderDomain.forAccount(self)
        NSFileProviderManager.add(domain) { error in
            if let error = error {
                print("Unable to add file provider domain: \(error.localizedDescription)")
            }
        }
    }

    public override func prepareForDeletion() {
        super.prepareForDeletion()

        let domain = NSFileProviderDomain.forAccount(self)
        NSFileProviderManager.remove(domain) { error in
            if let error = error {
                print("Unable to remove file provider domain: \(error.localizedDescription)")
            }
        }
    }
}
