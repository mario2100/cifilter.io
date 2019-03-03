//
//  AsyncFilterApplicator.swift
//  CIFilter.io
//
//  Created by Noah Gilmore on 12/26/18.
//  Copyright © 2018 Noah Gilmore. All rights reserved.
//

import Foundation
import RxSwift

struct ParameterValue {
    let name: String
    let value: Any
}

/**
 * Accepts subscriptions for updating filter parameters and generating an output image async.
 */
final class AsyncFilterApplicator {
    enum Error: Swift.Error {
        case generationFailed // Catch-all for CIFilter errors - image could not be generated from filter.outputImage
        case implementationError(message: String)
        case needsMoreParameters(names: [String])
    }

    enum Event {
        case generationStarted
        case generationCompleted(image: UIImage, totalTime: TimeInterval, parameters: [String: Any])
        case generationErrored(error: Error)
    }

    let events = PublishSubject<Event>()
    var timeStarted: TimeInterval? = nil

    private var bag = DisposeBag()
    private var currentFilter: FilterInfo? = nil
    private var currentParameterConfiguration = [String: Any]()
    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        return queue
    }()

    func set(filter: FilterInfo) {
        self.currentFilter = filter
        bag = DisposeBag() // dispose all current subscriptions
    }

    func set(value: Any, forParameterName name: String) {
        self.currentParameterConfiguration[name] = value
    }

    func addSubscription(for observable: Observable<ParameterValue>) {
        observable.throttle(0.3, scheduler: MainScheduler.instance).subscribe(onNext: { value in
            self.currentParameterConfiguration[value.name] = value.value
            self.generateOutputImageIfPossible()
        }).disposed(by: bag)
    }

    private func generateOutputImageIfPossible() {
        guard let filter = self.currentFilter else {
            events.onNext(.generationErrored(error: .implementationError(message: "No filter name provided")))
            return
        }
        let ciFilter = CIFilter(name: filter.name)!
        var stillNeededParameterNames = [String]()

        for parameter in filter.parameters {
            guard let value = self.currentParameterConfiguration[parameter.name] else {
                stillNeededParameterNames.append(parameter.name)
                continue
            }
            ciFilter.setValue(value, forKey: parameter.name)
        }
        if stillNeededParameterNames.count > 0 {
            events.onNext(.generationErrored(error: .needsMoreParameters(names: stillNeededParameterNames)))
        } else {
            print("Generating image with parameters: \(currentParameterConfiguration)")
            queue.cancelAllOperations()

            let blockOperation = BlockOperation()
            blockOperation.addExecutionBlock { [weak blockOperation] in
                guard let op = blockOperation, !op.isCancelled else {
                    return
                }
                guard var outputImage = ciFilter.outputImage else {
                    self.events.onNext(.generationErrored(error: .generationFailed))
                    return
                }
                let context = CIContext(options: nil)

                if outputImage.extent.isInfinite {
                    outputImage = outputImage.cropped(to: CGRect(x: 0, y: 0, width: 500, height: 500))
                }

                guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                    self.events.onNext(.generationErrored(error: .implementationError(message: "Could not create cgImage from CIContext")))
                    return
                }
                guard !op.isCancelled else { return }
                self.events.onNext(.generationCompleted(
                    image: UIImage(cgImage: cgImage),
                    totalTime: CACurrentMediaTime() - self.timeStarted!,
                    parameters: self.currentParameterConfiguration
                ))
            }
            queue.addOperation(blockOperation)
            self.events.onNext(.generationStarted)
            self.timeStarted = CACurrentMediaTime()
        }
    }
}
