//
//  Property.swift
//  CoreUtil
//
//  Created by yuki on 2020/07/06.
//  Copyright © 2020 yuki. All rights reserved.
//

import Combine

// from CoreUtil (https://github.com/ObuchiYuki/CoreUtil) 's Observable
@propertyWrapper
public struct LZObservable<Value> {
    @inlinable public var projectedValue: some Publisher<Value, Never> { subject }
    
    @usableFromInline let subject: CurrentValueSubject<Value, Never>
    
    @inlinable public var wrappedValue: Value {
        @inlinable get { subject.value }
        @inlinable set { subject.send(newValue) }
    }
    @inlinable public init(wrappedValue value: Value) {
        self.subject = CurrentValueSubject(value)
    }
}
