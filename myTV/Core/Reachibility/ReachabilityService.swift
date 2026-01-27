//
//  ReachabilityService.swift
//  myTV
//
//  Created by Anurag Chourasia on 23/01/26.
//

import Combine

protocol ReachabilityService {
    var isOnlinePublisher: AnyPublisher<Bool, Never> { get }
    var isOnline: Bool { get }
}
