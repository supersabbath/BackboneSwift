//
//  File.swift
//  Starz
//
//  Created by Fernando Canon on 05/11/15.
//  Copyright © 2015 Starzplay. All rights reserved.
//

import Foundation

infix operator <*> { associativity left }

infix operator <^> { associativity left }

public  func <*> <A, B>(f: ((A) -> B)?, a: A?) -> B? {
    switch f {
    case .some(let fx): return fx <^> a
    case .none: return .none
    }
}


public  func <^> <A, B>(f: (A) -> B, a: A?) -> B? {
    switch a {
    case .some(let x): return f(x)
    case .none: return .none
    }
}

infix operator >>> { associativity left precedence 150 }

public func >>> <A, B>(a: A?, f: (A) -> B?) -> B? {
    if let x = a {
        return f(x)
    } else {
        return .none
    }
}
