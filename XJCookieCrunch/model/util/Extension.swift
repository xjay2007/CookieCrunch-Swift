//
//  Extension.swift
//  XJCookieCrunch
//
//  Created by JunXie on 14-6-30.
//  Copyright (c) 2014 xiejun. All rights reserved.
//

import Foundation

extension Dictionary {
    static func loadJSONFromBundle(filename: String) -> Dictionary<String, AnyObject>? {
        let path = NSBundle.mainBundle().pathForResource(filename, ofType: "json")
        if (path == nil) {
            print("Could not find level file: \(filename)")
            return nil
        }
        
        let data: NSData? = try? NSData(contentsOfFile: path!, options: NSDataReadingOptions())
        if (data == nil) {
            print("Could not load level file:\(filename)")
            return nil
        }
        
        let dictionary: AnyObject! = try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
        if (dictionary == nil) {
            print("Level file \(filename) is not valid Json: ")
            return nil
        }
        
        return dictionary as? Dictionary<String, AnyObject>
    }
}