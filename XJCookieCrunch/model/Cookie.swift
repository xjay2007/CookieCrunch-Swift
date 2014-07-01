//
//  Cookie.swift
//  XJCookieCrunch
//
//  Created by JunXie on 14-6-30.
//  Copyright (c) 2014 xiejun. All rights reserved.
//

import SpriteKit

enum CookieType: Int {
    case Unknown = 0, Croissant, Cupcake, Danish, Donut, Macaroom, SugarCookie
    
    var spriteName: String {
    let spriteNames = [
        "Croissant",
        "Cupcake",
        "Danish",
        "Donut",
        "Macaroon",
        "SugarCookie"]
        
        return spriteNames[toRaw()-1]
    }
    
    var highlightedSpriteName: String {
    let highlightedSpriteNames = [
        "Croissant-Highlighted",
        "Cupcake-Highlighted",
        "Danish-Highlighted",
        "Donut-Highlighted",
        "Macaroon-Highlighted",
        "SugarCookie-Highlighted"]
        
        return highlightedSpriteNames[toRaw() - 1]
    }
    
    static func random() -> CookieType {
        return CookieType.fromRaw(Int(arc4random_uniform(6))+1)!
    }
}

class Cookie {
    // position
    var column: Int
    var row: Int
    let cookieType: CookieType
    var sprite: SKSpriteNode?
    
    init(column: Int, row: Int, cookieType: CookieType) {
        self.column = column
        self.row = row
        self.cookieType = cookieType
    }
}

extension CookieType: Printable {
    var description: String {
    return spriteName
    }
}
extension Cookie: Printable {
    var description: String {
    return "Type:\(self.cookieType) square:{\(self.column), \(self.row)}"
    }
}

func ==(lhs: Cookie, rhs: Cookie) -> Bool {
    return lhs.column == rhs.column && lhs.row == rhs.row
}

extension Cookie: Equatable {
}

extension Cookie: Hashable {
    var hashValue: Int {
    return row * 10 + column
    }
}