//
//  Array2D.swift
//  XJCookieCrunch
//
//  Created by JunXie on 14-6-30.
//  Copyright (c) 2014 xiejun. All rights reserved.
//

class Array2D<T> {
    let columns: Int
    let rows: Int
    var array: Array<T?> // private
    
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        self.array = Array<T?>(count: rows * columns, repeatedValue: nil)
    }
    
    subscript(column: Int, row: Int) -> T? {
        get {
            return array[row * self.columns + column]
        }
        set {
            array[row * self.columns + column] = newValue
        }
    }
}