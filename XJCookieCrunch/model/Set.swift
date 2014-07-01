//
//  Set.swift
//  XJCookieCrunch
//
//  Created by JunXie on 14-6-30.
//  Copyright (c) 2014 xiejun. All rights reserved.
//

class Set<T: Hashable> {
    var dictionary = Dictionary<T, Bool>() // private
    
    func addElement(newElement: T) {
        dictionary[newElement] = true
    }
    
    func removeElement(element: T) {
        dictionary[element] = nil
    }
    
    func containsElement(element: T) -> Bool {
        return dictionary[element] != nil
    }
    
    func allElements() -> T[] {
        return Array(dictionary.keys)
    }
    
    var count: Int {
    return dictionary.count
    }
    
    func unionSet(otherSet: Set<T>) -> Set<T> {
        var combined = Set<T>()
        
        for obj in dictionary.keys {
            combined.dictionary[obj] = true
        }
        
        for obj in otherSet.dictionary.keys {
            combined.dictionary[obj] = true
        }
        
        return combined
    }
    
}

extension Set: Sequence {
    // Sequence
    func generate() -> IndexingGenerator<Array<T>> {
        return allElements().generate()
    }
}

extension Set: Printable {
    var description: String {
    return dictionary.description
    }
}