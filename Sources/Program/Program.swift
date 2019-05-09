//
//  Program.swift
//  Geppetto
//
//  Created by JinSeo Yoon on 09/05/2019.
//  Copyright © 2019 rinndash. All rights reserved.
//

import RxSwift
import RxSwiftExt

public typealias Task<E, T> = Reader<E, Observable<T>>

public protocol ModelType {
    static var initial: Self { get }
}

public protocol Program {
    associatedtype Environment: EnvironmentType
    associatedtype Message
    associatedtype Model: ModelType
    typealias Cmd = Reader<Environment, Observable<Message?>>
    
    static var initialCommand: Cmd { get }
    static func update(model: Model, message: Message) -> (Model, Cmd)
}

public extension Program {
    static func app(_ message$: Observable<Message>) -> (Observable<(Model, Cmd)>) {
        return message$
            .scan((Model.initial, initialCommand)) { model_command, message -> (Self.Model, Cmd) in
                let (model, _) = model_command
                return update(model: model, message: message)
        }
    }
}

public extension Program {
    static func bind<V>(with view: V, environment: Environment) where V: View, V.Model == Model, V.Message == Message {
        let modelProxy: BehaviorSubject<Model> = BehaviorSubject(value: Model.initial)
        let commandProxy: BehaviorSubject<Cmd> = BehaviorSubject(value: initialCommand)
        
        let message$: Observable<Message> = Observable.merge(
            modelProxy.flatMap(view.run),
            commandProxy.flatMap(environment.run)
        )
        
        let model_command$: Observable<(Model, Cmd)> = app(message$)
            .share(replay: 1, scope: .forever)            
        
        let modelDisposable = model_command$.map { $0.0 }.bind(to: modelProxy)
        let cmdDisposable = model_command$.map { $0.1 }.bind(to: commandProxy)
        
        let disposables = Disposables.create(modelDisposable, cmdDisposable)
        disposables.disposed(by: view.disposeBag)
    }
}