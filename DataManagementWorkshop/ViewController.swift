//
//  ViewController.swift
//  DataManagementWorkshop
//
//  Created by student on 27/4/16.
//  Copyright © 2016 NguyenTrung. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var phone: UITextField!
    @IBOutlet weak var address: UITextField!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var status: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    var contacts: [String] = []
    
    var contactDB: COpaquePointer = nil
    var insertStatement: COpaquePointer = nil
    var selectStatement: COpaquePointer = nil
    var updateStatement: COpaquePointer = nil
    var deleteStatement: COpaquePointer = nil
    var selectAllStatement: COpaquePointer = nil
    
    let SQLITE_TRANSIENT = unsafeBitCast(-1, sqlite3_destructor_type.self)
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.delegate = self
        tableView.dataSource = self
        
        
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        print(paths)
        
        let docsDir = paths + "/contacts.sqlite"
        
        if (sqlite3_open(docsDir, &contactDB) == SQLITE_OK){
            let sql = "CREATE TABLE IF NOT EXISTS CONTACTS (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT, ADDRESS TEXT, PHONE TEXT)"
            if (sqlite3_exec(contactDB, sql, nil, nil, nil) != SQLITE_OK){
                print("Failed to create table")
                print(sqlite3_errmsg(contactDB))
            }
        } else {
            print("Failed to open database")
            print(sqlite3_errmsg(contactDB))
        }
        prepareStatements()
        loadAllContacts()
    }

    func prepareStatements(){
        var sqlString: String
        
        sqlString = "INSERT INTO CONTACTS (NAME, ADDRESS, PHONE) values (?,?,?)"
        var cSql = sqlString.cStringUsingEncoding(NSUTF8StringEncoding)
        sqlite3_prepare_v2(contactDB, cSql!, -1, &insertStatement, nil)
        
        sqlString = "SELECT address, phone FROM CONTACTS where name = ?"
        cSql = sqlString.cStringUsingEncoding(NSUTF8StringEncoding)
        sqlite3_prepare_v2(contactDB, cSql!, -1, &selectStatement, nil)
        
        sqlString = "UPDATE CONTACTS SET ADDRESS = ?, PHONE = ? WHERE name = ?"
        cSql = sqlString.cStringUsingEncoding(NSUTF8StringEncoding)
        sqlite3_prepare_v2(contactDB, cSql!, -1, &updateStatement, nil)

        sqlString = "DELETE FROM CONTACTS WHERE name = ?"
        cSql = sqlString.cStringUsingEncoding(NSUTF8StringEncoding)
        sqlite3_prepare_v2(contactDB, cSql!, -1, &deleteStatement, nil)
        
        sqlString = "SELECT name FROM CONTACTS"
        cSql = sqlString.cStringUsingEncoding(NSUTF8StringEncoding)
        sqlite3_prepare_v2(contactDB, cSql!, -1, &selectAllStatement, nil)
        
    }
    
    @IBAction func createContact(sender: AnyObject) {
        let nameStr = name.text as NSString?
        let addressStr = address.text as NSString?
        let phoneStr = phone.text as NSString?
        
        sqlite3_bind_text(insertStatement, 1, nameStr!.UTF8String, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(insertStatement, 2, addressStr!.UTF8String, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(insertStatement, 3, phoneStr!.UTF8String, -1, SQLITE_TRANSIENT)
        if (sqlite3_step(insertStatement) == SQLITE_DONE){
            status.text = "Contact added"
        } else {
            status.text = "Failed to add contact"
            print("Error code: \(sqlite3_errcode(contactDB))")
            let error = String.fromCString(sqlite3_errmsg(contactDB))
            print("Error Message: ",error)
        }
        sqlite3_reset(insertStatement)
        sqlite3_clear_bindings(insertStatement)
        loadAllContacts()

    }
    
    @IBAction func DeleteContact(sender: AnyObject) {
        
        let nameStr = name.text as NSString?
        sqlite3_bind_text(deleteStatement, 1, nameStr!.UTF8String, -1, SQLITE_TRANSIENT)
        if (sqlite3_step(deleteStatement) == SQLITE_DONE) {
            status.text = "Contact Deleted"
            name.text = ""
            address.text = ""
            phone.text = ""
            
        } else {
            status.text = "Failed to delete contact"
            print("Error code: \(sqlite3_errcode(contactDB))")
            let error = String.fromCString(sqlite3_errmsg(contactDB))
            print("Error Message: ",error)
        }
        sqlite3_reset(deleteStatement)
        sqlite3_clear_bindings(deleteStatement)
        
        loadAllContacts()

        
    }
    @IBAction func updateContact(sender: AnyObject) {
        let nameStr = name.text as NSString?
        let addressStr = address.text as NSString?
        let phoneStr = phone.text as NSString?
        sqlite3_bind_text(updateStatement, 1, nameStr!.UTF8String, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(updateStatement, 2, addressStr!.UTF8String, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(updateStatement, 3, phoneStr!.UTF8String, -1, SQLITE_TRANSIENT)
        if (sqlite3_step(updateStatement) == SQLITE_DONE){
            print("Contact Updated")
        } else {
            status.text = "Failed to update contact"
            print("Error code: \(sqlite3_errcode(contactDB))")
            let error = String.fromCString(sqlite3_errmsg(contactDB))
            print("Error Message: ",error)
        }
        sqlite3_reset(updateStatement)
        sqlite3_clear_bindings(updateStatement)
        loadAllContacts()

    }
    
    @IBAction func findContact(sender: AnyObject) {
        let nameStr = name.text as NSString?
        sqlite3_bind_text(selectStatement, 1, nameStr!.UTF8String, -1, SQLITE_TRANSIENT)
        if (sqlite3_step(selectStatement) == SQLITE_ROW){
            status.text = "Record retrieved"
            let address_buf = sqlite3_column_text(selectStatement, 0)
            address.text = String.fromCString(UnsafePointer<CChar>(address_buf))
            
            let phone_buf = sqlite3_column_text(selectStatement, 1)
            phone.text = String.fromCString(UnsafePointer<CChar>(phone_buf))
        } else {
            status.text = "Failed to retrieve contacts"
            address.text = " "
            phone.text = " "
            print("Error code: \(sqlite3_errcode(contactDB))")
            let error = String.fromCString(sqlite3_errmsg(contactDB))
            print("Error Message: ",error)
        }
        sqlite3_reset(selectStatement)
        sqlite3_clear_bindings(selectStatement)
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return contacts.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        cell.textLabel?.text = contacts[indexPath.row]
        return cell
    }
    
    func loadAllContacts() {
        contacts = []
        while (sqlite3_step(selectAllStatement) == SQLITE_ROW){
            let name_buf = sqlite3_column_text(selectAllStatement, 0)
            let name = String.fromCString(UnsafePointer<CChar>(name_buf))
            contacts.append(name!)
            print(name)
        } /*
        if (sqlite3)
        else {
            contacts = []
            status.text = "Failed to retrieve all the contacts"
            address.text = " "
            phone.text = " "
            print("Error code: \(sqlite3_errcode(contactDB))")
            let error = String.fromCString(sqlite3_errmsg(contactDB))
            print("Error Message: ",error)
        }
 */
        sqlite3_reset(selectAllStatement)
        tableView.reloadData()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

