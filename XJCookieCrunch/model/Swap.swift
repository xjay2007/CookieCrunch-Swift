//
//  Swap.swift
//  XJCookieCrunch
//
//  Created by JunXie on 14-6-30.
//  Copyright (c) 2014 xiejun. All rights reserved.
//

class Swap {
    var cookieA: Cookie
    var cookieB: Cookie
    
    init(cookieA: Cookie, cookieB: Cookie) {
        self.cookieA = cookieA
        self.cookieB = cookieB
    }
}

extension Swap: Printable {
    var description: String {
    return "swap \(cookieA) with \(cookieB)"
    }
}

func ==(lhs: Swap, rhs: Swap) -> Bool {
    return (lhs.cookieA == rhs.cookieA && lhs.cookieB == rhs.cookieB) || (lhs.cookieA == rhs.cookieB && lhs.cookieB == rhs.cookieA)
}

extension Swap: Hashable {
    var hashValue: Int {
//    return cookieA.hashValue ^ cookieB.hashValue
    return (cookieA.row * 10 + cookieA.column) ^ (cookieB.row * 10 + cookieB.column)
    }
}