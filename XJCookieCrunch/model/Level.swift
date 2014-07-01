//
//  Level.swift
//  XJCookieCrunch
//
//  Created by JunXie on 14-6-30.
//  Copyright (c) 2014 xiejun. All rights reserved.
//

import Foundation

let NumColumns = 9
let NumRows = 9

class Level {
    let cookies = Array2D<Cookie>(columns: NumColumns, rows: NumRows) // private
    let tiles = Array2D<Tile>(columns: NumColumns, rows: NumRows) // private
    var possibleSwaps = Set<Swap>()
    var comboMultiplier: Int = 0 // private
    
    let targetScore: Int!
    let maximumMoves: Int!
    
    init(filename: String) {
        // 1
        if let dictionary = Dictionary<String, AnyObject>.loadJSONFromBundle(filename) {
            // 2
            if let tilesArray: AnyObject = dictionary["tiles"] {
                // 3
                for (row, rowArray) in enumerate(tilesArray as Int[][]) {
                    // 4
                    let tileRow = NumRows - row - 1
                    // 5
                    for (column, value) in enumerate(rowArray) {
                        if value == 1 {
                            tiles[column, tileRow] = Tile()
                        }
                    }
                }
                //
                targetScore = (dictionary["targetScore"] as NSNumber).integerValue
                maximumMoves = (dictionary["moves"] as NSNumber).integerValue
            }
        }
    }
    
    func cookieAtColumn(column: Int, row: Int) -> Cookie? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return cookies[column, row]
    }
    
    func tileAtColumn(column: Int, row: Int) -> Tile? {
        assert(column >= 0 && column < NumColumns)
        assert(row >= 0 && row < NumRows)
        return tiles[column, row]
    }
    
    func shuffle() -> Set<Cookie> {
        var ret: Set<Cookie>
        do {
        ret = createInitialCookies()
        detectPossibleSwaps()
        } while possibleSwaps.count == 0
        
        return ret
    }
    
    func createInitialCookies() -> Set<Cookie> {
        var ret = Set<Cookie>()
        // 1
        for row in 0..NumRows {
            for column in 0..NumColumns {
                
                if tiles[column, row] != nil {
                    
                    // 2
                    var cookieType: CookieType // = CookieType.random()
                    do {
                        cookieType = CookieType.random()
                    } while ( (column >= 2 && cookies[column - 1, row]?.cookieType == cookieType && cookies[column - 2, row]?.cookieType == cookieType) || (row >= 2 && cookies[column, row - 1]?.cookieType == cookieType && cookies[column, row - 2]?.cookieType == cookieType) )
                    
                    // 3
                    let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                    self.cookies[column, row] = cookie
                    
                    // 4
                    ret.addElement(cookie)
                }
            }
        }
        
        return ret
    }
    
    func detectPossibleSwaps() {
        var ret = Set<Swap>()
        
        for row in 0..NumRows {
            for column in 0..NumColumns {
                if let cookie = cookies[column, row] {
                    // TODO: detection logic 
                    // Is it possible to swap this cookie with the one on the right?
                    if column < NumColumns - 1 {
                        // Have a cookie in this spot? If there is no tile, there is no cookie.
                        if let other = cookies[column + 1, row] {
                            // Swap them
                            cookies[column, row] = other
                            cookies[column + 1, row] = cookie
                            
                            // Is either cookie now part of a chain?
                            if hasChainAtColumn(column + 1, row: row) || hasChainAtColumn(column, row: row) {
                                ret.addElement(Swap(cookieA: cookie, cookieB: other))
                            }
                            
                            // Swap them back
                            cookies[column, row] = cookie
                            cookies[column + 1, row] = other
                        }
                    }
                    
                    // on the up
                    if row < NumRows - 1 {
                        if let other = cookies[column, row + 1] {
                            cookies[column, row] = other
                            cookies[column, row + 1] = cookie
                            
                            // Is either cookie now part of a chain?
                            if hasChainAtColumn(column, row: row + 1) ||
                                hasChainAtColumn(column, row: row) {
                                    ret.addElement(Swap(cookieA: cookie, cookieB: other))
                            }
                            
                            // Swap them back
                            cookies[column, row] = cookie
                            cookies[column, row + 1] = other
                        }
                    }
                }
            }
        }
        possibleSwaps = ret
    }
    func hasChainAtColumn(column: Int, row: Int) -> Bool {
        let cookieType = cookies[column, row]!.cookieType
        
        var horzLength = 1
        for var i = column - 1; i >= 0 && cookies[i, row]?.cookieType == cookieType; --i, ++horzLength { }
        for var i = column + 1; i < NumColumns && cookies[i, row]?.cookieType == cookieType; ++i, ++horzLength { }
        if horzLength >= 3 { return true }
        
        var vertLength = 1
        for var i = row - 1; i >= 0 && cookies[column, i]?.cookieType == cookieType; --i, ++vertLength { }
        for var i = row + 1; i < NumRows && cookies[column, i]?.cookieType == cookieType; ++i, ++vertLength { }
        return vertLength >= 3
    }
    
    func performSwap(swap: Swap) {
        let columnA = swap.cookieA.column
        let rowA = swap.cookieA.row
        let columnB = swap.cookieB.column
        let rowB = swap.cookieB.row
        
        cookies[columnA, rowA] = swap.cookieB
        swap.cookieB.column = columnA
        swap.cookieB.row = rowA
        
        cookies[columnB, rowB] = swap.cookieA
        swap.cookieA.column = columnB
        swap.cookieA.row = rowB
    }
    
    func isPossibleSwap(swap: Swap) -> Bool {
        return possibleSwaps.containsElement(swap)
    }
    
    func removeMatches() -> Set<Chain> {
        let horizontalChains = detectHorizontalMatches()
        let verticalChains = detectVerticalMatches()
        
        removeCookies(horizontalChains)
        removeCookies(verticalChains)
        
        calculateScores(horizontalChains)
        calculateScores(verticalChains)
        
        return horizontalChains.unionSet(verticalChains)
    }
    func detectHorizontalMatches() -> Set<Chain> {
        // 1
        let ret = Set<Chain>()
        // 2
        for row in 0..NumRows {
            for var column = 0; column < NumColumns - 2; {
                // 3
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    // 4
                    if cookies[column + 1, row]?.cookieType == matchType && cookies[column + 2, row]?.cookieType == matchType {
                        // 5
                        let chain = Chain(chainType: .Horizontal)
                        do {
                            chain.addCookie(cookies[column, row]!)
                            ++column
                        } while column < NumColumns && cookies[column, row]?.cookieType == matchType
                        
                        ret.addElement(chain)
                        continue
                    }
                }
                // 6 
                ++column
            }
        }
        
        return ret
    }
    func detectVerticalMatches() -> Set<Chain> {
        let ret = Set<Chain>()
        
        for column in 0..NumColumns {
            for var row = 0; row < NumRows - 2; {
                if let cookie = cookies[column, row] {
                    let matchType = cookie.cookieType
                    
                    if cookies[column, row + 1]?.cookieType == matchType &&
                        cookies[column, row + 2]?.cookieType == matchType {
                            
                        let chain = Chain(chainType: .Vertical)
                        do {
                            chain.addCookie(cookies[column, row]!)
                            ++row
                        }
                        while row < NumRows && cookies[column, row]?.cookieType == matchType
                        
                        ret.addElement(chain)
                        continue
                    }
                }
                ++row
            }
        }
        return ret
    }
    
    func removeCookies(chains: Set<Chain>) {
        for chain in chains {
            for cookie in chain.cookies {
                cookies[cookie.column, cookie.row] = nil
            }
        }
    }
    
    func fillHoles() -> Array<Array<Cookie>> {
        var columns = Array<Array<Cookie>>()
        // 1
        for column in 0..NumColumns {
            var array = Array<Cookie>()
            for row in 0..NumRows {
                // 2
                if tiles[column, row] != nil && cookies[column, row] == nil {
                    // 3
                    for lookup in (row + 1)..NumRows {
                        if let cookie = cookies[column, lookup] {
                            // 4
                            cookies[column, lookup] = nil
                            cookies[column, row] = cookie
                            cookie.row = row
                            // 5
                            array.append(cookie)
                            // 6
                            break
                        }
                    }
                }
            }
            // 7
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    func topUpCookies() -> Array<Array<Cookie>> {
        var columns = Cookie[][]()
        var cookieType: CookieType = .Unknown
        
        for column in 0..NumColumns {
            var array = Cookie[]()
            // 1
            for var row = NumRows - 1; row >= 0 && cookies[column, row] == nil; --row {
                // 2
                if tiles[column, row] != nil {
                    // 3
                    var newCookietype: CookieType
                    do {
                    newCookietype = CookieType.random()
                    } while newCookietype == cookieType
                    cookieType = newCookietype
                    // 4
                    let cookie = Cookie(column: column, row: row, cookieType: cookieType)
                    cookies[column, row] = cookie
                    array.append(cookie)
                }
            }
            // 5
            if !array.isEmpty {
                columns.append(array)
            }
        }
        return columns
    }
    
    func calculateScores(chains: Set<Chain>) {
        // 3-chains is 60 pts, 4-chains is 120, 5-chains is 180, and so on
        for chain in chains {
            chain.score = 60 * (chain.length - 2) * comboMultiplier
            ++comboMultiplier
        }
    }
    
    func resetComboMultiplier() {
        comboMultiplier = 1
    }
}
