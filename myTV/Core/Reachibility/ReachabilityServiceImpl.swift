//
//  ReachabilityServiceImpl.swift
//  myTV
//
//  Created by Anurag Chourasia on 24/01/26.
//

import Foundation
import Network
import Combine

final class ReachabilityServiceImpl: ReachabilityService {

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ReachabilityQueue")

    private let subject = CurrentValueSubject<Bool, Never>(true)

    var isOnlinePublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    var isOnline: Bool {
        subject.value
    }

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.subject.send(path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }
}
