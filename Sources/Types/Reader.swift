//
//  ReaderType.swift
//  Geppetto
//
//  Created by JinSeo Yoon on 09/05/2019.
//  Copyright © 2019 rinndash. All rights reserved.
//

public protocol ReaderType {
    associatedtype Env
    associatedtype Value
    var run: (Env) -> Value { get }
}

public extension ReaderType {
    func dimap<F, U>(from: @escaping (F) -> Env, to: @escaping (Value) -> U) -> Reader<F, U> {
        return Reader<F, U>.init(run: from >>> self.run >>> to)
    }
    
    func contraMap<F>(_ f: @escaping (F) -> Env) -> Reader<F, Value> {
        return dimap(from: f, to: id)
    }
    
    func map<U>(_ f: @escaping (Value) -> U) -> Reader<Env, U> {
        return dimap(from: id, to: f)
    }
}

public struct Reader<Environment, Value>: ReaderType {
    public let run: (Environment) -> Value
    
    public init(run: @escaping (Environment) -> Value) {
        self.run = run
    }
}
