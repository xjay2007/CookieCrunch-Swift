//
//  Chain.swift
//  XJCookieCrunch
//
//  Created by JunXie on 14-7-1.
//  Copyright (c) 2014 xiejun. All rights reserved.
//

class Chain {
    var cookies = Array<Cookie>() // private
    
    enum ChainType: Printable {
        case Horizontal
        case Vertical
        
        var description: String {
        switch self {
        case .Horizontal: return "Horizontal"
        case .Vertical: return "Vertical"
            }
        }
    }
    var chainType: ChainType
    
    init(chainType: ChainType) {
        self.chainType = chainType
    }
    
    func addCookie(cookie: Cookie) {
        cookies.append(cookie)
    }
   
    func firstCookie() -> Cookie {
        return cookies[0]
    }
    
    func lastCookie() -> Cookie {
        return cookies[cookies.count - 1]
    }
    
    var length: Int { return cookies.count }
    
    var score: Int = 0
}

extension Chain: Printable {
    var description: String {
    return "type:\(chainType) cookies:\(cookies)"
    }
}

func ==(lhs: Chain, rhs: Chain) -> Bool {
    return lhs.cookies == rhs.cookies
}

extension Chain: Hashable {
    var hashValue: Int {
//    return reduce(cookies, 0, {$0.hashValue ^ $1.hashValue})
    return reduce(cookies, 0, {$0.hashValue ^ ($1.row * 10 + $1.column)})
    }
}